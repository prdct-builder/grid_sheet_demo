import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/theme_borders.dart';
import '../design_system/theme_typography.dart';
import 'demo_card.dart';
import 'demo_detail_page.dart';
import 'demo_helpers.dart';
import 'demo_item.dart';
import 'demo_registry.dart';
import 'demo_browser_page.dart';
import 'home_palette.dart';

/// Dashboard launcher for every feature demo in [demoRegistry].
///
/// A hero-style homepage — generous whitespace, a soft layered-gradient
/// background, a centered brand header on wide viewports, and a staggered
/// fade/slide-up entrance for the card grid — styled from its own
/// [HomePalette] (see that file for why it isn't the shared
/// `design_system/theme_properties.dart` used by the 23 feature pages),
/// resolved fresh for both light and dark mode.
///
/// [crossAxisCount] caps the column count (6 by default, matching the large
/// desktop tier below); narrower viewports automatically show fewer columns
/// so cards never get squeezed below a usable width.
///
/// Tapping a card pushes [DemoDetailPage] in-app on mobile/desktop. On
/// Flutter Web it instead opens the demo's `/gridsheet/<id>` deep link in a
/// new browser tab, so the dashboard tab stays put and demos are shareable,
/// bookmarkable URLs.
class DemoHomePage extends StatefulWidget {
  final int crossAxisCount;

  const DemoHomePage({super.key, this.crossAxisCount = 6});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage>
    with SingleTickerProviderStateMixin {
  /// Five device tiers, named after their lower bound — every other
  /// width-dependent value below (header layout, page padding, grid column
  /// count) is derived from where `width` falls among these:
  /// mobile (<768), tablet (768–1023), laptop (1024–1439),
  /// desktop (1440–1919), large desktop (≥1920).
  static const double _tabletBreakpoint = 768;
  static const double _laptopBreakpoint = 1024;
  static const double _desktopBreakpoint = 1440;
  static const double _largeDesktopBreakpoint = 1920;

  /// Below this width the header stacks vertically instead of running as a
  /// row — mobile only.
  static const double _compactBreakpoint = _tabletBreakpoint;

  /// At and above this width the brand block is truly centered in the
  /// header row (not just left-of-actions) — laptop, desktop, and large
  /// desktop.
  static const double _wideBreakpoint = _laptopBreakpoint;

  /// Fixed grid-cell height tall enough for the redesigned [DemoCard]
  /// (icon badge, title, 2-line description, and a footer pinned to the
  /// bottom via `Spacer`) at every column width.
  static const double _cardExtent = 200;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  late final AnimationController _entranceController;

  /// Drives the card grid's scroll position for keyboard arrow-key
  /// scrolling — see [_handleGridKeyEvent].
  final ScrollController _gridScrollController = ScrollController();

  /// Holds focus for the card grid so arrow keys scroll it by default,
  /// without stealing focus away from the search field while it's in use
  /// (tapping into the search field moves focus there like any other
  /// focusable widget; arrow-key scrolling resumes once focus returns here).
  final FocusNode _gridFocusNode = FocusNode();

  /// Pixels scrolled per arrow-key press — comfortably less than one
  /// [_cardExtent] row so a single press feels like a nudge, not a jump.
  static const double _arrowScrollStep = 140;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entranceController.dispose();
    _gridScrollController.dispose();
    _gridFocusNode.dispose();
    super.dispose();
  }

  /// Scrolls the card grid back to the top — wired to a tap on the header
  /// brand (see [_buildHeader]), so clicking the logo feels like landing on
  /// the home page fresh again, the way a site logo usually behaves.
  /// A no-op if the grid isn't currently on screen (e.g. search has
  /// filtered every card out, showing [_NoResults] instead).
  void _scrollToTop() {
    if (!_gridScrollController.hasClients) return;
    _gridScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _handleGridKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_gridScrollController.hasClients) return KeyEventResult.ignored;

    final position = _gridScrollController.position;
    double target;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        target = position.pixels + _arrowScrollStep;
      case LogicalKeyboardKey.arrowUp:
        target = position.pixels - _arrowScrollStep;
      default:
        return KeyEventResult.ignored;
    }

    _gridScrollController.animateTo(
      target.clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  double _pagePaddingFor(double width) {
    if (width < _tabletBreakpoint) return 20;
    if (width < _laptopBreakpoint) return 28;
    if (width < _desktopBreakpoint) return 32;
    if (width < _largeDesktopBreakpoint) return 40;
    return 48;
  }

  /// Column count per device tier — mobile/tablet/laptop stay conservative
  /// enough to keep every card comfortably above a usable minimum width;
  /// desktop and large desktop deliberately step up further since there's
  /// plenty of horizontal room to spare at those widths.
  int _columnsFor(double width) {
    if (width < _tabletBreakpoint) return 1;
    if (width < _laptopBreakpoint) return 3;
    if (width < _desktopBreakpoint) return 4;
    if (width < _largeDesktopBreakpoint) return 5;
    return 6;
  }

  int _resolveColumnCount(double width) {
    return _columnsFor(width).clamp(1, widget.crossAxisCount);
  }

  /// Case-insensitive match against title/description — good enough for a
  /// ~20-item registry; no need for fuzzy matching or indexing.
  List<DemoItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return demoRegistry;
    return demoRegistry.where((item) {
      return item.title.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _openDemo(BuildContext context, DemoItem item) async {
    if (kIsWeb) {
      final url =
          Uri.base.resolve('${demoRoutePrefix.substring(1)}/${item.id}');
      final opened = await launchUrl(url, webOnlyWindowName: '_blank');
      if (!context.mounted || opened) return;
      // A blocked popup leaves the user with no feedback otherwise — the
      // tab just silently never opens.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t open "${item.title}" in a new tab')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DemoDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final pagePadding = _pagePaddingFor(width);
            return Column(
              children: [
                _Reveal(
                  parent: _entranceController,
                  end: 0.45,
                  child: _buildHeader(context, width, pagePadding),
                ),
                _Reveal(
                  parent: _entranceController,
                  begin: 0.15,
                  end: 0.55,
                  child:
                      _buildMetaRow(context, width, pagePadding, items.length),
                ),
                Expanded(
                  child: items.isEmpty
                      ? _NoResults(query: _query)
                      : Focus(
                          focusNode: _gridFocusNode,
                          autofocus: true,
                          onKeyEvent: _handleGridKeyEvent,
                          child: _buildGrid(context, items, pagePadding),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double width, double pagePadding) {
    final palette = HomePalette.of(context);
    final isCompact = width < _compactBreakpoint;
    final isWide = width >= _wideBreakpoint;

    final brand = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _scrollToTop,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/branding/app_icon.svg',
                width: 48,
                height: 48,
                colorFilter:
                    ColorFilter.mode(palette.heroIconFg, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: 'GridSheet', style: _HomeType.title(palette)),
                        TextSpan(
                          text: '  v$gridSheetVersion',
                          style: _HomeType.version(palette),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Fast, feature-rich, and customizable data grid for Flutter',
                      style: _HomeType.subtitle(palette),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(width: 12),
        const ThemeToggleButton(),
      ],
    );

    final menuButton = _MenuButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FeatureBrowserPage()),
      ),
    );

    if (isCompact) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pagePadding, 20, pagePadding, 20),
        child: Column(
          children: [
            Center(child: brand),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    expand: true,
                  ),
                ),
                const SizedBox(width: 12),
                const ThemeToggleButton(),
              ],
            ),
          ],
        ),
      );
    }

    if (!isWide) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pagePadding, 20, pagePadding, 8),
        child: Row(
          children: [
            menuButton,
            const SizedBox(width: 12),
            Expanded(child: brand),
            const SizedBox(width: 24),
            actions,
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(pagePadding, 20, pagePadding, 8),
      child: Row(
        children: [
          menuButton,
          const SizedBox(width: 12),
          IgnorePointer(
            child: Opacity(opacity: 0, child: actions),
          ),
          Expanded(child: Center(child: brand)),
          actions,
        ],
      ),
    );
  }

  Widget _buildMetaRow(
      BuildContext context, double width, double pagePadding, int shown) {
    final palette = HomePalette.of(context);
    final isCompact = width < _compactBreakpoint;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EXPLORE', style: _HomeType.eyebrow(palette)),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: palette.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$shown of ${demoRegistry.length} features',
          style: TextTypography.caption.copyWith(color: palette.textMuted),
        ),
      ],
    );

    final links = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ExternalLink(
          icon: Icons.link,
          label: 'pub.dev',
          url: 'https://pub.dev/packages/grid_sheet',
          tooltip: 'View grid_sheet on pub.dev',
        ),
        const SizedBox(width: 8),
        const _ExternalLink(
          icon: Icons.bug_report_outlined,
          label: 'Report Issues',
          url: 'https://github.com/prdct-builder/grid_sheet_issues',
          tooltip: 'Report an issue to gridsheet',
        ),
      ],
    );

    if (isCompact) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 8),
        child: links,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 8),
      child: Row(
        children: [
          label,
          const Spacer(),
          links,
        ],
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, List<DemoItem> items, double pagePadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _resolveColumnCount(constraints.maxWidth);
        return GridView.builder(
          controller: _gridScrollController,
          padding: EdgeInsets.fromLTRB(pagePadding, 16, pagePadding, 32),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: _cardExtent,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _Reveal(
              parent: _entranceController,
              begin: 0.25 + (index % 12) / 12 * 0.45,
              end: 0.75 + (index % 12) / 12 * 0.25,
              offsetY: 22,
              child: DemoCard(
                item: item,
                onTap: () => _openDemo(context, item),
              ),
            );
          },
        );
      },
    );
  }
}

/// Layered, extremely subtle radial-gradient wash behind the whole page —
/// Fades and slides [child] up into place as [parent] runs through
/// [begin]–[end] of its 0..1 range — the shared entrance choreography for
/// the header, meta row, and every grid card, driven by one
/// `AnimationController` rather than one per widget.
class _Reveal extends StatelessWidget {
  final Animation<double> parent;
  final double begin;
  final double end;
  final double offsetY;
  final Widget child;

  const _Reveal({
    required this.parent,
    required this.child,
    this.begin = 0.0,
    this.end = 0.4,
    this.offsetY = 14,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: parent,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * offsetY),
          child: child,
        ),
      ),
    );
  }
}

/// Premium type scale for this page's hero header — deliberately larger
/// than the shared `TextTypography` scale (tuned for in-page chrome), since
/// a hero title earns its own visual weight.
abstract final class _HomeType {
  static TextStyle title(HomePalette palette) => TextStyle(
        fontFamily: TextTypography.fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        height: 1.15,
        letterSpacing: 3,
        color: palette.textPrimary,
      );

  static TextStyle version(HomePalette palette) => TextStyle(
        fontFamily: TextTypography.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: palette.textMuted,
      );

  static TextStyle subtitle(HomePalette palette) => TextStyle(
        fontFamily: TextTypography.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: palette.textSecondary,
      );

  static TextStyle eyebrow(HomePalette palette) => TextStyle(
        fontFamily: TextTypography.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: palette.eyebrow,
      );
}

/// Soft, neutral (untinted) elevation shadow shared by the search field and
/// theme toggle — a violet-black wash in light mode, a plain black wash in
/// dark mode (a colored shadow barely reads against an already-dark
/// canvas). No accent color mixed in, unlike the old glow treatment.
List<BoxShadow> _neutralShadow(HomePalette palette) {
  final isDark = palette.canvas.computeLuminance() < 0.5;
  if (isDark) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];
  }
  return [
    BoxShadow(
      color: palette.cardShadowAmbient.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: palette.cardShadowAmbient.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Premium pill search field — soft bordered surface at rest, with an
/// animated border color while focused (no glow).
class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool expand;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    this.expand = false,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final focused = _focusNode.hasFocus;

    // Deliberately NOT keyed by isDark like DemoCard's decoration: this
    // container's child is a TextField holding a live FocusNode. Forcing a
    // fresh Element on every theme toggle would tear down and rebuild the
    // TextField mid-edit — if the user toggles theme while typing, the
    // cursor-blink restarts and an in-progress IME composition (e.g. CJK
    // input) could be interrupted. A plain, unkeyed RGB fade between two
    // opaque colors on a pill this small isn't the jarring "flash" the
    // large tiled cards had — so it's not worth that tradeoff here.
    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: widget.expand ? null : 260,
      height: 42,
      decoration: BoxDecoration(
        color: palette.searchBg,
        borderRadius: ThemeBorders.pill,
        border: Border.all(
          color: focused ? palette.searchBorderFocus : palette.searchBorder,
          width: focused ? 1.5 : 1,
        ),
        // Focus is communicated by the border color/width change above
        // only — no colored glow halo, just a neutral elevation shadow.
        boxShadow: _neutralShadow(palette),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: TextTypography.body.copyWith(color: palette.textPrimary),
        cursorColor: palette.primary,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'search…',
          hintStyle: TextTypography.body.copyWith(color: palette.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: focused ? palette.searchBorderFocus : palette.searchIcon,
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 38),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
                child: Icon(Icons.close_rounded,
                    size: 16, color: palette.textMuted),
              );
            },
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 30, minHeight: 30),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );

    return field;
  }
}

/// Reusable icon+text external link — pub.dev, the issue tracker, etc. A
/// subtle link that only picks up the accent color on hover — the same
/// rest/hover language as `DemoCard`'s "VIEW DEMO" footer link — with a
/// proper pointer cursor, tap ripple, and tooltip instead of a bare
/// `GestureDetector`, and a trailing "opens externally" glyph since it
/// always leaves the app in a new tab.
class _ExternalLink extends StatefulWidget {
  final IconData icon;
  final String label;
  final String url;
  final String tooltip;

  const _ExternalLink({
    required this.icon,
    required this.label,
    required this.url,
    required this.tooltip,
  });

  @override
  State<_ExternalLink> createState() => _ExternalLinkState();
}

class _ExternalLinkState extends State<_ExternalLink> {
  bool _hovering = false;

  void _setHovering(bool value) {
    if (_hovering == value) return;
    setState(() => _hovering = value);
  }

  Future<void> _open() async {
    final opened =
        await launchUrl(Uri.parse(widget.url), webOnlyWindowName: '_blank');
    if (!mounted || opened) return;
    // A blocked popup (or similar restriction) leaves the user with no
    // feedback otherwise — the tab just silently never opens.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Couldn\'t open the link — copy it instead: ${widget.url}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final color = _hovering ? palette.primary : palette.textMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: color),
                const SizedBox(width: 4),
                AnimatedDefaultTextStyle(
                  key: ValueKey<bool>(
                      Theme.of(context).brightness == Brightness.dark),
                  duration: const Duration(milliseconds: 150),
                  style: TextTypography.caption.copyWith(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    height: 1.0,
                  ),
                  child: Text(widget.label),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_outward_rounded, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the grid when [DemoHomePage]'s search query matches no
/// [DemoItem].
class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.emptyStateBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                size: 28, color: palette.emptyStateIcon),
          ),
          const SizedBox(height: 18),
          Text(
            'No demos match "$query"',
            style:
                TextTypography.bodyStrong.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword or clear the search.',
            style: TextTypography.body.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Pill icon-button that navigates to [FeatureBrowserPage] — same 42x42
/// pill visual language as [_ThemeToggleButton].
class _MenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Tooltip(
      message: 'Switch to browse features',
      child: InkWell(
        borderRadius: ThemeBorders.pill,
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.toggleBg,
            borderRadius: ThemeBorders.pill,
            border: Border.all(color: palette.toggleBorder),
          ),
          child: Icon(
            Icons.switch_right_rounded,
            size: 20,
            color: palette.toggleIcon,
          ),
        ),
      ),
    );
  }
}

// ThemeToggleButton moved to demo_helpers.dart so demo_browser_page.dart's
// _TopBar can use it too, without an import cycle (demo_home_page.dart
// already imports demo_browser_page.dart).
