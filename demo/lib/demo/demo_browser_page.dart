import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grid_sheet_demo/demo/constants.dart';

import '../design_system/theme_typography.dart';
import '../legacy/small_plain.dart';
import 'demo_detail_page.dart';
import 'demo_helpers.dart';
import 'demo_item.dart';
import 'demo_registry.dart';
import 'home_palette.dart';

class FeatureBrowserPage extends StatefulWidget {
  const FeatureBrowserPage({super.key});

  @override
  State<FeatureBrowserPage> createState() => _FeatureBrowserPageState();
}

class _FeatureBrowserPageState extends State<FeatureBrowserPage> {
  static const double _panelWidth = 280;
  static const double _collapsedPanelWidth = 56;
  static const double _wideBreakpoint = 800;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  bool _isPanelCollapsed = false;

  void _toggleCollapsed() =>
      setState(() => _isPanelCollapsed = !_isPanelCollapsed);

  final DemoDisplayOptions _displayOptions = DemoDisplayOptions();

  // Starts unselected — no demo is auto-picked on load. The content panel
  // shows SmallPlainGridSheet (see build()) until the viewer actually picks
  // something from the list, rather than always opening on whichever demo
  // happens to sort first alphabetically.
  DemoItem? _selected;

  /// `true` for [_switchIndicatorMinDuration] after selecting a new item —
  /// see [_select]. Shows [_FeatureLoadingIndicator] in the content panel
  /// instead of building [DemoDetailView] (and, inside it, a real
  /// `GridSheet`) while it's true.
  ///
  /// Held for a fixed minimum duration rather than just until the next
  /// frame: most of these demos build fast enough that a single-frame
  /// indicator (~16ms) comes and goes between two frames the eye never
  /// distinguishes — it reads as an empty flicker, not a loading state.
  /// A held minimum makes the transition register as deliberate feedback.
  bool _isSwitching = false;

  // Long enough for _FeatureLoadingIndicator's pulse/rotate/dots animation
  // to visibly read as motion rather than a single static frame.
  static const _switchIndicatorMinDuration = Duration(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    _displayOptions.dispose();
    super.dispose();
  }

  /// Case-insensitive match against title/description — same approach as
  /// `DemoHomePage._filteredItems`. Filtering never affects [_selected]/the
  /// content panel — only which items the list itself shows — so search
  /// never yanks away whatever's currently open, even if it stops matching.
  List<DemoItem> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return demoRegistry;
    return demoRegistry.where((item) {
      return item.title.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _select(DemoItem item) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    setState(() {
      _selected = item;
      _isSwitching = true;
    });
    // See _switchIndicatorMinDuration's dartdoc for why this is a held
    // minimum rather than just "until the next frame".
    Future.delayed(_switchIndicatorMinDuration, () {
      if (!mounted) return;
      setState(() => _isSwitching = false);
    });
  }

  void _goHome() {
    if (_selected == null) return;
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.canvas,
      drawer: Drawer(
        width: _isPanelCollapsed ? _collapsedPanelWidth : null,
        backgroundColor: palette.canvas,
        child: SafeArea(
          child: _FeatureList(
            items: _filteredItems,
            selected: _selected,
            onSelect: _select,
            searchController: _searchController,
            onSearchChanged: (value) => setState(() => _query = value),
            collapsed: _isPanelCollapsed,
            onToggleCollapsed: _toggleCollapsed,
          ),
        ),
      ),
      body: SafeArea(
        child: DemoDisplayOptionsScope(
          notifier: _displayOptions,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= _wideBreakpoint;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(displayOptions: _displayOptions, onTitleTap: _goHome),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWide) ...[
                          SizedBox(
                            width: _isPanelCollapsed
                                ? _collapsedPanelWidth
                                : _panelWidth,
                            child: _FeatureList(
                              items: _filteredItems,
                              selected: _selected,
                              onSelect: _select,
                              searchController: _searchController,
                              onSearchChanged: (value) =>
                                  setState(() => _query = value),
                              collapsed: _isPanelCollapsed,
                              onToggleCollapsed: _toggleCollapsed,
                            ),
                          ),
                          Container(width: 1, color: palette.cardBorder),
                        ],
                        Expanded(
                          child: _isSwitching
                              ? const _FeatureLoadingIndicator()
                              : _selected == null
                                  // nothing selected yet
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: const SmallPlainGridSheet(
                                        key: ValueKey('unselected'),
                                      ),
                                    )
                                  : DemoDetailView(
                                      key: ValueKey(_selected!.id),
                                      item: _selected!,
                                    ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shown in the content panel for [_FeatureBrowserPageState.
/// _switchIndicatorMinDuration] after selecting a new demo, before that
/// demo's real content mounts — see [_FeatureBrowserPageState._isSwitching].
///
/// Same visual language as `layout_widgets.dart`'s `_TickerLoadingWidget`
/// (`GridSheet.loadingIndicator` demo) — a rotating icon inside a pulsing
/// badge, a label, and a trio of sequentially-fading dots — rather than a
/// plain [CircularProgressIndicator], for a consistent "something's
/// loading" feel across the demo app.
class _FeatureLoadingIndicator extends StatefulWidget {
  const _FeatureLoadingIndicator();

  @override
  State<_FeatureLoadingIndicator> createState() =>
      _FeatureLoadingIndicatorState();
}

class _FeatureLoadingIndicatorState extends State<_FeatureLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.88 + 0.12 * (1 - (t - 0.5).abs() * 2);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary.withValues(alpha: 0.14),
                  ),
                  child: Transform.rotate(
                    angle: t * 2 * math.pi,
                    child: Icon(
                      Icons.sync_outlined,
                      color: palette.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Loading feature…',
                style: TextTypography.body.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (t + i / 3) % 1.0;
                  final opacity = 0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity.clamp(0.25, 1.0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: palette.primary, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final DemoDisplayOptions displayOptions;
  final VoidCallback onTitleTap;

  const _TopBar({required this.displayOptions, required this.onTitleTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = HomePalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Back',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back,
                  color: palette.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onTitleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'GridSheet Features',
                style: TextTypography.cardTitle.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
          ),
          const Spacer(),
          _DisplayOptionsButton(displayOptions: displayOptions),
          const SizedBox(width: 4),
          const ThemeToggleButton(applyStyle: false),
        ],
      ),
    );
  }
}

/// Context menu (icon + a custom dropdown panel) letting the viewer
/// hide/show each demo's header banner, toolbar, and status bar — toggles
/// [displayOptions], which [DemoDisplayOptionsScope] makes visible to
/// `FeaturePageTemplate`/`DemoDetailView` below it.
///
/// Deliberately not a [PopupMenuButton]: Flutter's stock one always closes
/// after a single [PopupMenuButton.onSelected] fires, with no supported way
/// to keep it open across several selections — wrong for a set of
/// independent on/off options the viewer may want to flip more than one of
/// in a row. [OverlayPortal] + [CompositedTransformFollower] instead builds
/// a panel that stays open through any number of taps on its own checkbox
/// rows, and closes only via the full-screen barrier behind it (tapping
/// anywhere outside the panel) or the icon itself.
class _DisplayOptionsButton extends StatefulWidget {
  final DemoDisplayOptions displayOptions;

  const _DisplayOptionsButton({required this.displayOptions});

  @override
  State<_DisplayOptionsButton> createState() => _DisplayOptionsButtonState();
}

class _DisplayOptionsButtonState extends State<_DisplayOptionsButton> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => _DisplayOptionsOverlay(
          link: _layerLink,
          displayOptions: widget.displayOptions,
          onDismiss: _overlayController.hide,
        ),
        child: Tooltip(
          message: 'Display options',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _overlayController.toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.tune_rounded,
                  size: 20, color: palette.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dropdown panel itself, painted into the app's root [Overlay] (via
/// [OverlayPortal]) rather than [_DisplayOptionsButton]'s own local tree —
/// necessary so it can render on top of everything else and extend past
/// [_DisplayOptionsButton]'s own bounds. [link]/[CompositedTransformFollower]
/// is what still anchors it visually to the button despite that.
class _DisplayOptionsOverlay extends StatelessWidget {
  final LayerLink link;
  final DemoDisplayOptions displayOptions;
  final VoidCallback onDismiss;

  const _DisplayOptionsOverlay({
    required this.link,
    required this.displayOptions,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Stack(
      children: [
        // Full-screen, otherwise-invisible tap target: closes the panel on
        // any tap outside it, without blocking anything else on screen
        // while the panel is closed (it only exists while open).
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: palette.canvas,
            child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.cardBorder),
              ),
              // Rebuilds the checkmarks live as each option is toggled —
              // this is exactly what lets the panel stay open and reflect
              // several toggles in a row, unlike a menu that closes after
              // one.
              child: ListenableBuilder(
                listenable: displayOptions,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OptionRow(
                      label: 'Show Header',
                      value: displayOptions.showHeader,
                      onTap: displayOptions.toggleHeader,
                    ),
                    _OptionRow(
                      label: 'Show Toolbar',
                      value: displayOptions.showToolbar,
                      onTap: displayOptions.toggleToolbar,
                    ),
                    _OptionRow(
                      label: 'Show Footer',
                      value: displayOptions.showStatusBar,
                      onTap: displayOptions.toggleStatusBar,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One checkbox-style row inside [_DisplayOptionsOverlay] — tapping it
/// toggles [value] via [onTap] without closing the panel.
class _OptionRow extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              size: Constants.featureIconSize,
              color: value ? palette.primary : palette.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextTypography.body.copyWith(color: palette.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final List<DemoItem> items;
  final DemoItem? selected;
  final ValueChanged<DemoItem> onSelect;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  const _FeatureList({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.searchController,
    required this.onSearchChanged,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              _CollapseToggleButton(
                collapsed: collapsed,
                onTap: onToggleCollapsed,
              ),
              SizedBox(width: collapsed ? 0 : 4),
              if (!collapsed)
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: TextTypography.body
                        .copyWith(color: palette.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search features…',
                      hintStyle: TextTypography.body
                          .copyWith(color: palette.textMuted),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: Constants.featureIconSize,
                          color: palette.searchIcon),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: Constants.featureIconSize,
                              color: palette.textMuted,
                            ),
                          );
                        },
                      ),
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      filled: true,
                      fillColor: palette.searchBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: palette.searchBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: palette.searchBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: palette.searchBorderFocus),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? (collapsed
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No features match your search.',
                        style: TextTypography.body
                            .copyWith(color: palette.textMuted),
                      ),
                    ))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.id == selected?.id;

                    if (collapsed) {
                      return Tooltip(
                        message: item.title,
                        child: InkWell(
                          onTap: () => onSelect(item),
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primary.withValues(alpha: 0.08)
                                  : null,
                              border: isSelected
                                  ? BorderDirectional(
                                      start: BorderSide(
                                          color: palette.primary, width: 3),
                                    )
                                  : null,
                            ),
                            child: Icon(
                              item.icon,
                              size: Constants.featureIconSize,
                              color: isSelected
                                  ? palette.primary
                                  : palette.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListTile(
                      minTileHeight: 38,
                      dense: true,
                      leading: Icon(
                        item.icon,
                        size: Constants.featureIconSize,
                        color: isSelected ? palette.primary : palette.textMuted,
                      ),
                      title: Text(
                        item.title,
                        style: TextTypography.body.copyWith(
                          color: isSelected
                              ? palette.primary
                              : palette.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor:
                          palette.primary.withValues(alpha: 0.08),
                      onTap: () => onSelect(item),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.cardBorder)),
          ),
          child: collapsed
              ? Tooltip(
                  message: '${items.length} of ${demoRegistry.length} features',
                  child: Text(
                    '${items.length}',
                    style: TextTypography.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                )
              : Text(
                  '${items.length} of ${demoRegistry.length} features',
                  style:
                      TextTypography.caption.copyWith(color: palette.textMuted),
                ),
        ),
      ],
    );
  }
}

class _CollapseToggleButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;

  const _CollapseToggleButton({required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);

    return Tooltip(
      message: collapsed ? 'Expand Menu' : 'Collapse Menu',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.menu_rounded,
            size: Constants.featureIconSize + 2,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
