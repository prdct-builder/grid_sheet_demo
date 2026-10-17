import 'package:flutter/material.dart';

import '../design_system/theme_borders.dart';
import '../design_system/theme_typography.dart';
import 'demo_item.dart';
import 'home_palette.dart';

/// A single feature-demo tile on the dashboard grid: icon badge, title,
/// description, and a "View demo" affordance pinned to the bottom.
///
/// Feels interactive even before clicking — hovering lifts and gently
/// scales the card, switches its border to the accent color, and deepens
/// its (neutral, untinted) shadow; pressing settles it back down for a
/// tactile press. No glow: every shadow here is a plain alpha step of
/// [HomePalette.cardShadowAmbient], never a color-tinted blur halo. All
/// transitions are implicit (`Animated*`) and finish within ~200ms so the
/// interaction reads as smooth, not sluggish.
class DemoCard extends StatefulWidget {
  final DemoItem item;
  final VoidCallback onTap;

  const DemoCard({super.key, required this.item, required this.onTap});

  @override
  State<DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<DemoCard> {
  static const _duration = Duration(milliseconds: 200);
  static const _curve = Curves.easeOutCubic;

  bool _hovering = false;
  bool _pressed = false;

  void _setHovering(bool value) {
    if (_hovering == value) return;
    setState(() => _hovering = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    // A hero dashboard card needs to visibly float even at rest in both
    // themes, so dark mode gets its own resting elevation here: a stronger
    // grounding shadow and a stronger border than the light-mode hairline.
    // Every shadow is a plain alpha step of cardShadowAmbient — no accent
    // color mixed in, so hovering deepens elevation without glowing.
    final isDark = palette.canvas.computeLuminance() < 0.5;
    final liftY = _pressed ? -2.0 : (_hovering ? -6.0 : 0.0);
    final scale = _pressed ? 0.98 : (_hovering ? 1.015 : 1.0);
    final borderColor = _hovering
        ? palette.cardBorderHover.withValues(alpha: 0.55)
        : palette.cardBorder;
    final restingShadow = isDark
        ? [
            BoxShadow(
              color: palette.cardShadowAmbient.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : [
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
    final hoverShadow = [
      BoxShadow(
        color: palette.cardShadowAmbient.withValues(alpha: isDark ? 0.6 : 0.10),
        blurRadius: isDark ? 26 : 18,
        offset: Offset(0, isDark ? 14 : 10),
      ),
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovering(true),
      onExit: (_) {
        _setHovering(false);
        _setPressed(false);
      },
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: scale,
          duration: _duration,
          curve: _curve,
          child: AnimatedContainer(
            // Keyed by [isDark] so a theme toggle mounts a *fresh*
            // AnimatedContainer instead of animating the existing one from
            // its old (light or dark) decoration to the new one. Without
            // this, every card on screen would tween its fill/border/shadow
            // across the full light<->dark gap over [_duration] while
            // everything else (Scaffold background, text color, etc.) snaps
            // instantly — the mismatch reads as a white/black flash. Hover
            // and press still animate smoothly through this same
            // AnimatedContainer, since neither of those changes the key.
            key: ValueKey<String>('card-$isDark'),
            duration: _duration,
            curve: _curve,
            transform: Matrix4.translationValues(0, liftY, 0),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: ThemeBorders.roundedXl,
              border: Border.all(
                color: borderColor,
                width: _hovering ? 1.3 : 1,
              ),
              boxShadow: _hovering ? hoverShadow : restingShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: ThemeBorders.roundedXl,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: ThemeBorders.roundedXl,
                splashColor: palette.primary.withValues(alpha: 0.06),
                highlightColor: palette.primary.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        // Purely theme-driven (no hover state feeds this
                        // decoration) — same flash risk and same fix as the
                        // outer card AnimatedContainer above.
                        key: ValueKey<String>('card-icon-$isDark'),
                        duration: _duration,
                        curve: _curve,
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.cardIconBg,
                          borderRadius: ThemeBorders.roundedLg,
                        ),
                        child: AnimatedScale(
                          scale: _hovering ? 1.08 : 1.0,
                          duration: _duration,
                          curve: _curve,
                          child: Icon(widget.item.icon,
                              color: palette.primary, size: 22),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.item.title,
                        style: TextStyle(
                          fontFamily: TextTypography.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          height: 1.3,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.item.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.item.description!,
                          style: TextTypography.body
                              .copyWith(color: palette.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 12),
                      AnimatedDefaultTextStyle(
                        key: ValueKey<String>('card-footer-$isDark'),
                        duration: _duration,
                        curve: _curve,
                        style: TextTypography.labelSmall.copyWith(
                          color: _hovering
                              ? palette.footerLinkHover
                              : palette.footerLink,
                          letterSpacing: 0.5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('VIEW DEMO'),
                            AnimatedContainer(
                              duration: _duration,
                              curve: _curve,
                              margin: EdgeInsets.only(left: _hovering ? 8 : 4),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: _hovering
                                    ? palette.footerLinkHover
                                    : palette.footerLink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
