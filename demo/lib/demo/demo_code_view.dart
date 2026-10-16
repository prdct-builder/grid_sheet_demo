import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

const _codeFontFamily = 'JetBrains Mono';
const _codeFontFamilyFallback = [
  'Inter',
  'Menlo',
  'Consolas',
  'Liberation Mono',
  'Courier New',
];
const _codeFontSize = 12.5;
const _codeLineHeight = 1.6;
const _lineHeightPx = _codeFontSize * _codeLineHeight;
const _codeTopPadding = 12.0;

/// Chrome colors for the editor shell (title bar, tab, breadcrumb, gutter,
/// status bar) — deliberately hardcoded to familiar VS Code Dark+/Light+
/// values rather than derived from the host app's [ColorScheme]. A real
/// code editor doesn't reskin itself to match whatever app embeds it; that
/// fixed, unmistakable chrome is what reads as "a code editor" rather than
/// "a themed text box".
class _EditorPalette {
  final Color chrome;
  final Color chromeBorder;
  final Color editorBg;
  final Color gutterText;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color statusBg;
  final Color statusText;
  final Color searchMatch;
  final Color searchMatchCurrent;

  const _EditorPalette({
    required this.chrome,
    required this.chromeBorder,
    required this.editorBg,
    required this.gutterText,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.statusBg,
    required this.statusText,
    required this.searchMatch,
    required this.searchMatchCurrent,
  });

  static const dark = _EditorPalette(
    chrome: Color(0xFF252526),
    chromeBorder: Color(0xFF3C3C3C),
    editorBg: Color(0xFF1E1E1E),
    gutterText: Color(0xFF6E7681),
    text: Color(0xFFCCCCCC),
    textMuted: Color(0xFF9D9D9D),
    accent: Color(0xFF3B9EFF),
    statusBg: Color(0xFF007ACC),
    statusText: Color(0xFFFFFFFF),
    searchMatch: Color(0x33D2A700),
    searchMatchCurrent: Color(0x66FFA500),
  );

  static const light = _EditorPalette(
    chrome: Color(0xFFF3F3F3),
    chromeBorder: Color(0xFFE0E0E0),
    editorBg: Color(0xFFFFFFFF),
    gutterText: Color(0xFF237893),
    text: Color(0xFF1E1E1E),
    textMuted: Color(0xFF6E6E6E),
    accent: Color(0xFF005FB8),
    statusBg: Color(0xFF007ACC),
    statusText: Color(0xFFFFFFFF),
    searchMatch: Color(0x40FFD700),
    searchMatchCurrent: Color(0x80FFA500),
  );
}

/// Drops every `//`, `///` and `/* */` comment from Dart [source], via the
/// same `highlight` parse `DemoCodeView` already uses for syntax coloring
/// (its dart grammar tags every comment variant with `className == 'comment'`)
/// rather than a regex, which would be fragile against `//` inside string
/// literals (e.g. a URL). Leftover blank lines where a comment used to be
/// are collapsed so the result reads like tidy, comment-free source rather
/// than code full of gaps.
String _stripDartComments(String source) {
  final buffer = StringBuffer();

  void visit(Node node) {
    if (node.className == 'comment') return;
    if (node.value != null) {
      buffer.write(node.value);
    } else {
      node.children?.forEach(visit);
    }
  }

  highlight.parse(source, language: 'dart').nodes?.forEach(visit);

  final lines = buffer.toString().split('\n').map((line) => line.trimRight());
  final cleaned = <String>[];
  for (final line in lines) {
    final isBlank = line.trim().isEmpty;
    if (isBlank && cleaned.isNotEmpty && cleaned.last.trim().isEmpty) {
      continue;
    }
    cleaned.add(line);
  }
  while (cleaned.isNotEmpty && cleaned.first.trim().isEmpty) {
    cleaned.removeAt(0);
  }
  while (cleaned.isNotEmpty && cleaned.last.trim().isEmpty) {
    cleaned.removeLast();
  }
  return cleaned.join('\n');
}

/// Shows a [DemoItem.sourcePath]'s file as syntax-highlighted, read-only
/// Dart source inside a self-contained VS Code-style editor shell (title
/// bar, find-in-file, gutter, status bar) — loaded from the app's asset
/// bundle at runtime (see the `lib/features/` entry in `pubspec.yaml`'s
/// `assets:` list) so this is always the exact, current source, never a
/// hand-copied snippet that can drift out of sync with the running demo.
class DemoCodeView extends StatefulWidget {
  final String sourcePath;

  /// Closes the panel this editor is shown in, if any (wired to the tab's
  /// close button, the title bar's close button and the Escape shortcut).
  final VoidCallback? onClose;

  const DemoCodeView({super.key, required this.sourcePath, this.onClose});

  @override
  State<DemoCodeView> createState() => _DemoCodeViewState();
}

class _DemoCodeViewState extends State<DemoCodeView> {
  late Future<String> _sourceFuture;

  // Explicit controllers, one per axis, each bound to its own Scrollbar —
  // relying on the ambient PrimaryScrollController with two nested
  // SingleChildScrollViews is ambiguous about which one it attaches to,
  // and was the reason vertical dragging previously did nothing.
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<int> _matchLines = const [];
  int _currentMatch = -1;

  @override
  void initState() {
    super.initState();
    _sourceFuture = _loadSource();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant DemoCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourcePath != widget.sourcePath) {
      _sourceFuture = _loadSource();
      _closeSearch();
    }
  }

  Future<String> _loadSource() async {
    final raw =
        await DefaultAssetBundle.of(context).loadString(widget.sourcePath);
    return _stripDartComments(raw);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _copy(String source) async {
    await Clipboard.setData(ClipboardData(text: source));
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_searchOpen && _searchController.text.isEmpty) return;
    setState(() {
      _searchOpen = false;
      _searchController.clear();
      _matchLines = const [];
      _currentMatch = -1;
    });
  }

  void _onQueryChanged() {
    // Recomputed against the currently-loaded source snapshot; cheap enough
    // (line-by-line contains()) for demo-sized files to redo on every
    // keystroke without debouncing.
    _sourceFuture.then((source) {
      if (!mounted) return;
      final query = _searchController.text;
      if (query.isEmpty) {
        setState(() {
          _matchLines = const [];
          _currentMatch = -1;
        });
        return;
      }
      final lines = source.split('\n');
      final lowerQuery = query.toLowerCase();
      final matches = <int>[
        for (var i = 0; i < lines.length; i++)
          if (lines[i].toLowerCase().contains(lowerQuery)) i,
      ];
      setState(() {
        _matchLines = matches;
        _currentMatch = matches.isEmpty ? -1 : 0;
      });
      if (matches.isNotEmpty) _scrollToLine(matches.first);
    });
  }

  void _nextMatch() {
    if (_matchLines.isEmpty) return;
    setState(() => _currentMatch = (_currentMatch + 1) % _matchLines.length);
    _scrollToLine(_matchLines[_currentMatch]);
  }

  void _previousMatch() {
    if (_matchLines.isEmpty) return;
    setState(
      () => _currentMatch =
          (_currentMatch - 1 + _matchLines.length) % _matchLines.length,
    );
    _scrollToLine(_matchLines[_currentMatch]);
  }

  void _scrollToLine(int lineIndex) {
    if (!_verticalController.hasClients) return;
    final target = (_codeTopPadding + lineIndex * _lineHeightPx) -
        (_verticalController.position.viewportDimension / 2);
    _verticalController.animateTo(
      target.clamp(0.0, _verticalController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? _EditorPalette.dark : _EditorPalette.light;
    final codeTheme = isDark ? vs2015Theme : vsTheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_searchOpen) {
            _closeSearch();
          } else {
            widget.onClose?.call();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _openSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _openSearch,
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: palette.chrome,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TitleBar(
                palette: palette,
                onSearch: _searchOpen ? _closeSearch : _openSearch,
                searchActive: _searchOpen,
                onCopy: () => _sourceFuture.then(_copy),
                onClose: widget.onClose,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _searchOpen
                    ? _SearchBar(
                        palette: palette,
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        matchCount: _matchLines.length,
                        currentMatch: _currentMatch,
                        onNext: _nextMatch,
                        onPrevious: _previousMatch,
                        onClose: _closeSearch,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              Expanded(
                child: FutureBuilder<String>(
                  future: _sourceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return ColoredBox(
                        color: palette.editorBg,
                        child: Center(
                          child:
                              CircularProgressIndicator(color: palette.accent),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return ColoredBox(
                        color: palette.editorBg,
                        child: const Center(
                          child: Text(
                            'Could not load source',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    }

                    final source = snapshot.data!;
                    return _EditorBody(
                      palette: palette,
                      codeTheme: codeTheme,
                      source: source,
                      verticalController: _verticalController,
                      horizontalController: _horizontalController,
                      matchLines: _matchLines,
                      currentMatchLine: _currentMatch >= 0
                          ? _matchLines[_currentMatch]
                          : null,
                    );
                  },
                ),
              ),
              FutureBuilder<String>(
                future: _sourceFuture,
                builder: (context, snapshot) {
                  final lineCount = snapshot.hasData
                      ? '\n'.allMatches(snapshot.data!).length + 1
                      : null;
                  return _StatusBar(
                    palette: palette,
                    lineCount: lineCount,
                    matchCount: _matchLines.length,
                    searchOpen: _searchOpen,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top chrome row: a "Source Code" label plus find / copy / close actions
/// — the equivalent of a native window's title bar.
class _TitleBar extends StatelessWidget {
  final _EditorPalette palette;
  final VoidCallback onSearch;
  final bool searchActive;
  final VoidCallback onCopy;
  final VoidCallback? onClose;

  const _TitleBar({
    required this.palette,
    required this.onSearch,
    required this.searchActive,
    required this.onCopy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.data_object, size: 15, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            'Source Code',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          _TitleBarIconButton(
            icon: Icons.search,
            tooltip: 'Find in file',
            active: searchActive,
            palette: palette,
            onPressed: onSearch,
          ),
          _TitleBarIconButton(
            icon: Icons.copy_outlined,
            tooltip: 'Copy code',
            palette: palette,
            onPressed: onCopy,
          ),
          if (onClose != null)
            _TitleBarIconButton(
              icon: Icons.close,
              tooltip: 'Close',
              palette: palette,
              onPressed: onClose,
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _TitleBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final _EditorPalette palette;
  final VoidCallback? onPressed;

  const _TitleBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.palette,
    this.active = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? palette.accent.withValues(alpha: 0.18) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 15,
              color: active ? palette.accent : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline find-in-file bar: query field, match count, prev/next, close.
class _SearchBar extends StatelessWidget {
  final _EditorPalette palette;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchCount;
  final int currentMatch;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  const _SearchBar({
    required this.palette,
    required this.controller,
    required this.focusNode,
    required this.matchCount,
    required this.currentMatch,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.isNotEmpty;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.editorBg,
        border: Border(bottom: BorderSide(color: palette.chromeBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: palette.chrome,
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: palette.accent.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 14, color: palette.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (_) => onNext(),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.text,
                        fontFamily: _codeFontFamily,
                        fontFamilyFallback: _codeFontFamilyFallback,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Find in file',
                      ),
                    ),
                  ),
                  if (hasQuery)
                    Text(
                      matchCount == 0
                          ? 'No results'
                          : '${currentMatch + 1} of $matchCount',
                      style: TextStyle(fontSize: 11, color: palette.textMuted),
                    ),
                ],
              ),
            ),
          ),
          _TitleBarIconButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: 'Previous match',
            palette: palette,
            onPressed: matchCount > 0 ? onPrevious : null,
          ),
          _TitleBarIconButton(
            icon: Icons.keyboard_arrow_down,
            tooltip: 'Next match',
            palette: palette,
            onPressed: matchCount > 0 ? onNext : null,
          ),
          _TitleBarIconButton(
            icon: Icons.close,
            tooltip: 'Close search',
            palette: palette,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// The gutter + syntax-highlighted source itself, with search-match bars
/// painted behind the text (a lightweight stand-in for a minimap search
/// overview) and both scroll axes wired to explicit controllers.
class _EditorBody extends StatelessWidget {
  final _EditorPalette palette;
  final Map<String, TextStyle> codeTheme;
  final String source;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final List<int> matchLines;
  final int? currentMatchLine;

  const _EditorBody({
    required this.palette,
    required this.codeTheme,
    required this.source,
    required this.verticalController,
    required this.horizontalController,
    required this.matchLines,
    required this.currentMatchLine,
  });

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(source).length + 1;
    final gutterWidth = 20.0 + (lineCount.toString().length * 9.0);

    return ColoredBox(
      color: palette.editorBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: verticalController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      for (final line in matchLines)
                        Positioned(
                          top: _codeTopPadding + line * _lineHeightPx,
                          left: 0,
                          right: 0,
                          height: _lineHeightPx,
                          child: ColoredBox(
                            color: line == currentMatchLine
                                ? palette.searchMatchCurrent
                                : palette.searchMatch,
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: gutterWidth,
                            padding: const EdgeInsets.only(
                                top: _codeTopPadding, right: 8),
                            child: Text(
                              List.generate(lineCount, (i) => '${i + 1}')
                                  .join('\n'),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: _codeFontFamily,
                                fontFamilyFallback: _codeFontFamilyFallback,
                                fontSize: _codeFontSize,
                                height: _codeLineHeight,
                                letterSpacing: 1,
                                color: palette.gutterText,
                              ),
                            ),
                          ),
                          Container(width: 1, color: palette.chromeBorder),
                          Expanded(
                            child: Scrollbar(
                              controller: horizontalController,
                              thumbVisibility: true,
                              notificationPredicate: (notification) =>
                                  notification.metrics.axis == Axis.horizontal,
                              child: SingleChildScrollView(
                                controller: horizontalController,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth:
                                        constraints.maxWidth - gutterWidth - 1,
                                  ),
                                  child: SelectionArea(
                                    child: _SelectableHighlightView(
                                      source,
                                      language: 'dart',
                                      theme: codeTheme,
                                      padding: const EdgeInsets.fromLTRB(
                                          12, _codeTopPadding, 24, 16),
                                      textStyle: const TextStyle(
                                        fontFamily: _codeFontFamily,
                                        fontFamilyFallback:
                                            _codeFontFamilyFallback,
                                        fontSize: _codeFontSize,
                                        height: _codeLineHeight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A drop-in replacement for `flutter_highlight`'s `HighlightView` that
/// renders through [Text.rich] instead of a raw [RichText]. `RichText` only
/// participates in an ancestor [SelectionArea]'s selection if it's handed
/// that [SelectionRegistrar] explicitly (`RichText.selectionRegistrar`) —
/// `HighlightView` never does, so wrapping it in [SelectionArea] alone is a
/// no-op. [Text] performs that lookup (`SelectionContainer.maybeOf`)
/// internally, so swapping the leaf widget is enough to make selection work
/// without forking the highlighting logic itself, which is copied verbatim
/// from `flutter_highlight`'s `HighlightView._convert`.
class _SelectableHighlightView extends StatelessWidget {
  final String source;
  final String language;
  final Map<String, TextStyle> theme;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const _SelectableHighlightView(
    this.source, {
    required this.language,
    required this.theme,
    this.padding,
    this.textStyle,
  });

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultFontFamily = 'monospace';

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    var baseStyle = TextStyle(
      fontFamily: _defaultFontFamily,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    if (textStyle != null) {
      baseStyle = baseStyle.merge(textStyle);
    }

    return Container(
      color: theme[_rootKey]?.backgroundColor,
      padding: padding,
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children:
              _convert(highlight.parse(source, language: language).nodes!),
        ),
      ),
    );
  }
}

/// Bottom VS Code-style status bar: language indicator on the left, file
/// stats on the right.
class _StatusBar extends StatelessWidget {
  final _EditorPalette palette;
  final int? lineCount;
  final int matchCount;
  final bool searchOpen;

  const _StatusBar({
    required this.palette,
    required this.lineCount,
    required this.matchCount,
    required this.searchOpen,
  });

  @override
  Widget build(BuildContext context) {
    // statusBg is the same fixed VS Code blue in both _EditorPalette.light
    // and .dark, so its text/icons always read against that one background
    // — routed through palette.statusText (rather than a hardcoded
    // Colors.white) so there's a single source of truth for that color,
    // not a second static one duplicating it.
    final textStyle = TextStyle(fontSize: 11, color: palette.statusText);
    final mutedIconColor = palette.statusText.withValues(alpha: 0.7);

    return Container(
      height: 24,
      color: palette.statusBg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.data_object, size: 12, color: palette.statusText),
          const SizedBox(width: 4),
          Text('Dart', style: textStyle),
          const SizedBox(width: 14),
          Icon(Icons.visibility_outlined, size: 12, color: mutedIconColor),
          const SizedBox(width: 4),
          Text('Read-only', style: textStyle),
          const Spacer(),
          if (searchOpen) ...[
            Text('$matchCount results', style: textStyle),
            const SizedBox(width: 14),
          ],
          if (lineCount != null) Text('$lineCount lines', style: textStyle),
          const SizedBox(width: 14),
          Text('UTF-8', style: textStyle),
          const SizedBox(width: 14),
          Text('LF', style: textStyle),
        ],
      ),
    );
  }
}
