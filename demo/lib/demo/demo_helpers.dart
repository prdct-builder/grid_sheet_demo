// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../design_system/design_system.dart';
import '../design_system/app_theme.dart';
import 'constants.dart';
import 'home_palette.dart';

/// Wraps every tab body with a consistent rounded card shell: optional
/// [DemoToolbar] -> grid -> [DemoStatusBar].
///
/// [title], [description] and [icon] are no longer rendered here — that
/// same content now lives in the dashboard's header (next to the back
/// button) via `DemoItem`/`DemoDetailPage` in `lib/demo/`. They stay as
/// required parameters purely so none of the 23 `features/` call sites need
/// to change.
class FeaturePageTemplate extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Widget? toolbar;
  final Widget grid;
  final ValueListenable<String>? status;
  final double gridPadding;

  const FeaturePageTemplate({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.toolbar,
    required this.grid,
    this.status,
    this.gridPadding = ThemeSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    final displayOptions = DemoDisplayOptionsScope.of(context);
    final showToolbar =
        toolbar != null && (displayOptions?.showToolbar ?? true);
    final showStatus =
        status != null && (displayOptions?.showStatusBar ?? true);

    return Padding(
      padding: const EdgeInsets.all(ThemeSpacing.sm),
      child: Container(
        decoration: ThemeComponents.card(context.colors),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: ThemeSpacing.sm),
            if (showToolbar) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: ThemeSpacing.sm),
                child: toolbar!,
              ),
              const SizedBox(height: ThemeSpacing.sm),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gridPadding),
                child: ClipRRect(
                  borderRadius: ThemeBorders.roundedMd,
                  child: grid,
                ),
              ),
            ),
            if (showStatus) ...[
              const SizedBox(height: ThemeSpacing.sm),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: ThemeSpacing.sm),
                child: DemoStatusBar(message: status!),
              ),
            ],
            const SizedBox(height: ThemeSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// A small pill-shaped action button used inside every feature toolbar.
class DemoActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  const DemoActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget pill = Container(
      padding: const EdgeInsets.all(ThemeSpacing.sm),
      decoration:
          ThemeComponents.accentPill(color, filled: false, dark: isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextTypography.label.copyWith(color: color)),
        ],
      ),
    );
    Widget button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: ThemeBorders.pill,
          child: pill,
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}

/// A pill-shaped ON/OFF toggle button used to flip a `GridSheetConfiguration`
/// flag live and see its effect on the grid immediately.
class DemoToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? tooltip;

  const DemoToggleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = value ? color : colors.textMuted;
    Widget pill = Container(
      padding: const EdgeInsets.all(ThemeSpacing.sm),
      decoration: ThemeComponents.accentPill(
        color,
        filled: false,
        toggle: true,
        dark: isDark,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(value ? icon : Icons.circle_outlined,
              size: 15, color: activeColor),
          const SizedBox(width: 6),
          Text('$label: ${value ? 'ON' : 'OFF'}',
              style: TextTypography.label.copyWith(color: activeColor)),
        ],
      ),
    );
    Widget button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: ThemeBorders.roundedSm,
          child: pill,
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}

/// The horizontally-scrollable strip of [DemoActionButton]/[DemoToggleButton]
/// actions shown above the grid.
class DemoToolbar extends StatefulWidget {
  final List<Widget> sections;

  const DemoToolbar({super.key, required this.sections});

  @override
  State<DemoToolbar> createState() => _DemoToolbarState();
}

class _DemoToolbarState extends State<DemoToolbar> {
  static const double _scrollStep = 220;

  final ScrollController _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrowVisibility);
    // The controller's ScrollPosition doesn't exist until after the first
    // layout, so the initial overflow state (are there even enough buttons
    // to scroll at all) can only be read a frame later.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateArrowVisibility());
  }

  @override
  void didUpdateWidget(covariant DemoToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The toolbar's own button set can change size (a demo toggling extra
    // buttons in/out) — recheck overflow once that new layout has happened.
    if (oldWidget.sections.length != widget.sections.length) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateArrowVisibility());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrowVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _updateArrowVisibility() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final canLeft = position.pixels > position.minScrollExtent + 0.5;
    final canRight = position.pixels < position.maxScrollExtent - 0.5;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  // Below this width (matches DemoHomePage's own mobile tier), the arrows
  // are dropped even when the strip overflows — touch already scrolls the
  // strip directly, and the arrows just eat space on a narrow screen.
  static const double _mobileBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;
    return Row(
      children: [
        if (_canScrollLeft && !isMobile) ...[
          _ToolbarScrollArrow(
            icon: Icons.chevron_left,
            onTap: () => _scrollBy(-_scrollStep),
          ),
          const SizedBox(width: ThemeSpacing.xs),
        ],
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            // On desktop/web, Flutter's default ScrollBehavior only
            // allows touch and stylus to drag-scroll — a plain mouse
            // click-drag is ignored unless the mouse is explicitly added
            // to dragDevices. The arrow buttons above/below are the
            // primary way to reach overflowed buttons either way.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  ...PointerDeviceKind.values,
                },
              ),
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: Row(children: widget.sections),
              ),
            ),
          ),
        ),
        if (_canScrollRight && !isMobile) ...[
          const SizedBox(width: ThemeSpacing.xs),
          _ToolbarScrollArrow(
            icon: Icons.chevron_right,
            onTap: () => _scrollBy(_scrollStep),
          ),
        ],
      ],
    );
  }
}

/// Small round click-to-scroll button shown at either end of [DemoToolbar]
/// only while there's actually more content in that direction to reveal.
class _ToolbarScrollArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarScrollArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.14) : colors.border,
            ),
          ),
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
      ),
    );
  }
}

/// Thin status/log strip pinned under the grid (footer) — used to surface callback
/// output (selection events, cell changes, reorder events, etc.) live.
class DemoStatusBar extends StatelessWidget {
  final ValueListenable<String> message;
  // Below this width the description is clipped to one line with a tappable
  // info icon to view it in full; above it, there's enough room to just show
  // the whole description inline, so the icon would be redundant clutter.
  static const double _compactBreakpoint = 700;

  const DemoStatusBar({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<String>(
      valueListenable: message,
      builder: (context, value, _) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSpacing.md,
          vertical: ThemeSpacing.sm,
        ),
        decoration: ThemeComponents.subtleStrip(colors),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < _compactBreakpoint;

                  final statusVal = Text(
                    value.isEmpty ? 'Ready — interact with the grid.' : value,
                    style: TextTypography.code.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: isCompact ? 1 : null,
                    overflow:
                        isCompact ? TextOverflow.ellipsis : TextOverflow.clip,
                  );

                  return Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: ThemeSpacing.sm),
                      Expanded(
                        child: statusVal,
                      ),
                      if (isCompact) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () =>
                              showDemoDialog(context, 'Message', value),
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
                    ],
                  );
                },
              ),
            ),
            LoadTimeLabel(
              style: TextTypography.code.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-viewer toggles for whether [FeaturePageTemplate] shows its
/// [DemoToolbar]/[DemoStatusBar] sections (and, via `DemoDetailView` in
/// `demo_detail_page.dart`, its own header banner) — surfaced as a "Display
/// options" context menu in `FeatureBrowserPage`.
///
/// A [ChangeNotifier] rather than three separate flags/callbacks so a
/// single [DemoDisplayOptionsScope] ancestor can drive every option with
/// one `InheritedNotifier` dependency.
class DemoDisplayOptions extends ChangeNotifier {
  bool _showHeader = true;
  bool _showToolbar = true;
  bool _showStatusBar = true;

  bool get showHeader => _showHeader;
  bool get showToolbar => _showToolbar;
  bool get showStatusBar => _showStatusBar;

  void toggleHeader() {
    _showHeader = !_showHeader;
    notifyListeners();
  }

  void toggleToolbar() {
    _showToolbar = !_showToolbar;
    notifyListeners();
  }

  void toggleStatusBar() {
    _showStatusBar = !_showStatusBar;
    notifyListeners();
  }
}

/// Makes a [DemoDisplayOptions] instance available to [FeaturePageTemplate]
/// (and `DemoDetailView`) anywhere below it — in particular, across the
/// `DemoItem.builder(context)` boundary, which is a fixed
/// `Widget Function(BuildContext)` signature that can't otherwise carry a
/// constructor parameter down into each `features/` page.
///
/// [FeaturePageTemplate.build] calls [of] every build, which registers a
/// dependency on this [InheritedNotifier] — so every page showing it
/// rebuilds automatically whenever [DemoDisplayOptions.notifyListeners]
/// fires, with no manual listener wiring at each of the 23 call sites.
/// [of] returns `null` (falling back to "show everything") where no scope
/// is in the ancestry — e.g. the standalone `/gridsheet/<id>` route — so
/// behavior there is unchanged.
class DemoDisplayOptionsScope extends InheritedNotifier<DemoDisplayOptions> {
  const DemoDisplayOptionsScope({
    super.key,
    required DemoDisplayOptions super.notifier,
    required super.child,
  });

  static DemoDisplayOptions? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DemoDisplayOptionsScope>()
        ?.notifier;
  }
}

void showDemoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

void showDemoDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(content),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    ),
  );
}

Future<String?> showDemoInputDialog(
  BuildContext context,
  String label, {
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(label),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

GridSheetStyleConfiguration styleConfig(
  BuildContext context, {
  bool colorEvenOdd = true,
}) {
  final colors = context.colors;

  return GridSheetStyleConfiguration(
    gridBackgroundColor: colors.surface,
    headerColor: colors.surfaceSubtle,
    filterColor: colors.surfaceSubtle,
    rowColor: colors.surface,
    evenRowColor: colorEvenOdd ? colors.canvas : null,
    oddRowColor: colorEvenOdd ? colors.surface : null,
    selectionColor: colors.primary,
    gridBorderColor: colors.border,
    headerRowBorderColor: colors.border,
    filterRowBorderColor: colors.border,
    bottomBarBorderColor: colors.border,
    rowBorderColor: colors.border,
    columnBorderColor: colors.border,
    headerTextStyle: TextTypography.label,
    gridBorderRadius: ThemeBorders.roundedMd,
    cellTextFieldBorderColor: colors.border,
  );
}

GridSheetScrollBarConfiguration scrollConfig(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < Constants.mobileBreakpoint;

  return GridSheetScrollBarConfiguration(
    radius: Radius.circular(ThemeBorders.radiusLg),
    thickness: ThemeBorders.radiusMd,
    scrollbarBuilder:
        isMobile ? (context, child, controller, axis) => child : null,
  );
}

/// Pill icon-button that flips [appThemeMode] between light and dark, with
/// a soft rotate-and-fade transition between the sun/moon icons.
///
/// Shared by [DemoHomePage] and [FeatureBrowserPage]'s `_TopBar` — lives
/// here (not in either of those files) since demo_home_page.dart already
/// imports demo_browser_page.dart, so putting it in either would create an
/// import cycle.
class ThemeToggleButton extends StatelessWidget {
  final bool applyStyle;

  const ThemeToggleButton({super.key, this.applyStyle = true});

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, mode, __) {
        final toggleIsDark = mode == ThemeMode.system
            ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
            : mode == ThemeMode.dark;
        Widget button;

        if (applyStyle) {
          button = AnimatedContainer(
            // This pill's decoration only ever changes because of a theme
            // toggle (there's no hover/press state on this button), so it
            // should never actually animate — it should snap in lockstep with
            // the rest of the theme. Keying by toggleIsDark forces exactly
            // that: a fresh AnimatedContainer with no previous value to tween
            // from. See DemoCard's identically-keyed AnimatedContainer.
            key: ValueKey<bool>(toggleIsDark),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.toggleBg,
              borderRadius: ThemeBorders.pill,
              border: Border.all(color: palette.toggleBorder),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: 0.72, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                toggleIsDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                key: ValueKey<bool>(toggleIsDark),
                size: 19,
                color: palette.toggleIcon,
              ),
            ),
          );
        } else {
          button = Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              toggleIsDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: palette.toggleIcon,
            ),
          );
        }
        return Tooltip(
          message: 'Toggle light / dark theme',
          child: InkWell(
            borderRadius: ThemeBorders.pill,
            onTap: () {
              appThemeMode.value =
                  toggleIsDark ? ThemeMode.light : ThemeMode.dark;
            },
            child: button,
          ),
        );
      },
    );
  }
}
