import 'package:flutter/material.dart';
import 'package:grid_sheet_demo/demo/demo_helpers.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';

import 'demo_code_view.dart';
import 'demo_item.dart';

/// Full-page shell for a single [DemoItem]: wraps [DemoDetailView] in a
/// [Scaffold] and sets the browser tab title via [Title]. Reached two
/// ways — pushed from [DemoHomePage] on mobile/desktop, or loaded directly
/// for a `/gridsheet/<id>` URL (e.g. a web deep link opened in a new
/// browser tab) — both land on this same shell.
class DemoDetailPage extends StatelessWidget {
  final DemoItem item;

  const DemoDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // On Flutter Web, Title updates document.title to the nearest
    // ancestor's value — so a demo opened via a direct /gridsheet/<id> URL
    // shows e.g. "Column Operations" in that tab instead of the app-wide
    // MaterialApp.title ("GridSheet Features").
    return Title(
      title: item.title,
      color: colorScheme.primary,
      child: Scaffold(
        body: SafeArea(child: DemoDetailView(item: item)),
      ),
    );
  }
}

/// The reusable content behind [DemoDetailPage]: a header banner with an
/// icon badge, title and the *full* description — the "feature header"
/// content every `features/` page used to render inline now lives here
/// instead — above the widget built by [DemoItem.builder].
///
/// The header is a plain (non-`AppBar`) widget so it can grow to fit
/// [DemoItem.detailDescription] in full, however long it is, rather than
/// being clipped to a fixed toolbar height.
///
/// No [Scaffold] of its own — this is meant to be embedded directly inside
/// a host page's body ([DemoDetailPage]'s standalone shell, or
/// `FeatureBrowserPage`'s content panel).
///
/// Most `features/` widgets never call [recordGridLoadTime] themselves from
/// their GridSheet's `onLoaded`, so the load-time label (shown in each
/// demo's status bar) would stay blank for them. Calling it here instead,
/// once this widget's first frame has painted, covers every demo uniformly
/// without touching any of the 23 `features/` files.
///
/// Pass a `key` derived from [DemoItem.id] (e.g. `ValueKey(item.id)`) at
/// call sites that swap [item] in place without remounting the surrounding
/// tree — `FeatureBrowserPage` does this when switching between demos — so
/// this widget's own [State] (and [recordGridLoadTime]'s per-view firing)
/// resets for the new item instead of silently carrying over the previous
/// one's.
class DemoDetailView extends StatefulWidget {
  final DemoItem item;

  const DemoDetailView({super.key, required this.item});

  @override
  State<DemoDetailView> createState() => _DemoDetailViewState();
}

class _DemoDetailViewState extends State<DemoDetailView> {
  bool _showCode = false;

  // Per-instance load timer — see DemoViewLoadTimeScope's dartdoc (why the
  // app-wide appLoadDurationMs/recordGridLoadTime alone isn't enough once a
  // demo can be swapped out for another within one session). Started here,
  // in initState, rather than at field-initializer time: a StatefulWidget's
  // initState runs right when its Element is actually created, which is
  // exactly when this demo view starts being built for real — an
  // instance-per-field initializer would race that by a negligible but
  // real amount.
  final Stopwatch _loadStopwatch = Stopwatch();
  final ValueNotifier<int?> _viewLoadDurationMs = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _loadStopwatch.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStopwatch.stop();
      _viewLoadDurationMs.value = _loadStopwatch.elapsedMilliseconds;
      // Also keeps the app-wide metric (used by legacy routes/direct loads
      // with no DemoViewLoadTimeScope of their own) working as before.
      recordGridLoadTime();
    });
  }

  @override
  void dispose() {
    _viewLoadDurationMs.dispose();
    super.dispose();
  }

  DemoItem get item => widget.item;

  void _toggleCode() => setState(() => _showCode = !_showCode);
  void _closeCode() => setState(() => _showCode = false);

  @override
  Widget build(BuildContext context) {
    final showHeader = DemoDisplayOptionsScope.of(context)?.showHeader ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          _DemoDetailHeader(
            item: item,
            showCode: _showCode,
            onToggleCode: _toggleCode,
          ),
        Expanded(
          child: DemoViewLoadTimeScope(
            notifier: _viewLoadDurationMs,
            child: Stack(
              children: [
                Positioned.fill(child: Builder(builder: item.builder)),
                _CodePanelOverlay(
                  open: _showCode,
                  sourcePath: item.sourcePath,
                  onClose: _closeCode,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The header banner itself: icon badge + title + full-length,
/// freely-wrapping description, plus a "Code" toggle. The load-time label
/// now lives in the demo's status bar (see `DemoStatusBar` in
/// `demo_helpers.dart`), not here.
class _DemoDetailHeader extends StatelessWidget {
  final DemoItem item;
  final bool showCode;
  final VoidCallback onToggleCode;

  const _DemoDetailHeader({
    required this.item,
    required this.showCode,
    required this.onToggleCode,
  });

  // Below this width the description is clipped to one line with a tappable
  // info icon to view it in full; above it, there's enough room to just show
  // the whole description inline, so the icon would be redundant clutter.
  static const double _compactBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final banner = Container(
      decoration: isDark
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            )
          : BoxDecoration(color: colorScheme.surfaceContainer),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.detailDescription != null) ...[
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact =
                          constraints.maxWidth < _compactBreakpoint;
                      final description = Text(
                        item.detailDescription!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: isCompact ? 1 : null,
                        overflow: isCompact
                            ? TextOverflow.ellipsis
                            : TextOverflow.clip,
                      );
                      if (!isCompact) return description;
                      return Row(
                        children: [
                          Expanded(child: description),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _showFullDescription(context, item),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          _ViewCodeButton(active: showCode, onPressed: onToggleCode),
        ],
      ),
    );

    return banner;
  }

  void _showFullDescription(BuildContext context, DemoItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Text(item.detailDescription!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Pill button that opens/closes the sliding code panel — styled to match
/// the app's other pill toggles (see `_ThemeToggleButton` in
/// demo_home_page.dart) but a single toggle rather than a two-way switch,
/// since the panel is an overlay rather than a second full-screen state.
class _ViewCodeButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const _ViewCodeButton({required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DemoActionButton(
      label: 'Code',
      icon: Icons.code,
      color: colorScheme.primary,
      onPressed: onPressed,
      tooltip: 'View the source code for this demo',
    );
  }
}

/// Slides [DemoCodeView] in from the right edge of its parent [Stack] as a
/// floating, resizable panel — a scrim dims the demo behind it, and
/// tapping the scrim (or Esc, handled inside [DemoCodeView]) closes it.
/// On narrow (mobile) widths the panel widens to fill the available space
/// instead of a slice of it, since a fixed-width slide-over wouldn't leave
/// the code readable.
class _CodePanelOverlay extends StatefulWidget {
  final bool open;
  final String sourcePath;
  final VoidCallback onClose;

  const _CodePanelOverlay({
    required this.open,
    required this.sourcePath,
    required this.onClose,
  });

  @override
  State<_CodePanelOverlay> createState() => _CodePanelOverlayState();
}

class _CodePanelOverlayState extends State<_CodePanelOverlay> {
  static const double _defaultWidth = 640;
  static const double _minWidth = 380;
  static const double _compactBreakpoint = 700;

  double _width = _defaultWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isCompact = maxWidth < _compactBreakpoint;
        final panelWidth = isCompact
            ? maxWidth
            : _width.clamp(
                _minWidth, (maxWidth - 96).clamp(_minWidth, maxWidth));

        final panelContent = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isCompact)
              _ResizeHandle(
                onDrag: (delta) {
                  setState(() {
                    _width = (_width - delta).clamp(
                        _minWidth, (maxWidth - 96).clamp(_minWidth, maxWidth));
                  });
                },
              ),
            Expanded(
              child: DemoCodeView(
                sourcePath: widget.sourcePath,
                onClose: widget.onClose,
              ),
            ),
          ],
        );

        return IgnorePointer(
          ignoring: !widget.open,
          child: Stack(
            children: [
              AnimatedOpacity(
                opacity: widget.open ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: colorScheme.scrim.withValues(alpha: 0.35),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                right: widget.open ? 0 : -panelWidth - 32,
                width: panelWidth,
                child: PhysicalModel(
                  color: colorScheme.surface,
                  elevation: 24,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: isCompact
                      ? BorderRadius.zero
                      : const BorderRadius.horizontal(left: Radius.circular(8)),
                  child: panelContent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Thin drag strip on the panel's left edge for resizing it, with a
/// resize cursor on desktop/web so it reads as draggable before the user
/// even touches it.
class _ResizeHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const _ResizeHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 4,
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
