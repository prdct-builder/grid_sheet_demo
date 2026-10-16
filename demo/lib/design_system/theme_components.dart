import 'package:flutter/material.dart';

import 'theme_borders.dart';
import 'theme_properties.dart';

/// Reusable decoration/shadow presets for the demo app's chrome — call these
/// instead of hand-rolling a `BoxDecoration` per widget, so every card/pill
/// in every feature page shares the same elevation language.
abstract final class ThemeComponents {
  /// The rounded card shell every feature page's grid sits inside.
  static BoxDecoration card(ThemeProperties colors) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: ThemeBorders.roundedLg,
      border: Border.all(color: colors.border),
      boxShadow: cardShadow(colors),
    );
  }

  /// Toolbar / status-bar strip — one step down from [card]. Dark mode gets
  /// a translucent white-alpha tint plus a faint border instead of
  /// [ThemeProperties.surfaceSubtle], which reads as too close to [card]'s
  /// own surface color to look like a distinct, recessed strip. Light mode
  /// is unchanged (flat [ThemeProperties.surfaceSubtle], no border).
  static BoxDecoration subtleStrip(ThemeProperties colors) {
    if (_isDark(colors)) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: ThemeBorders.roundedMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      );
    }
    return BoxDecoration(
      color: colors.surfaceSubtle,
      borderRadius: ThemeBorders.roundedMd,
    );
  }

  static bool _isDark(ThemeProperties colors) =>
      colors.canvas.computeLuminance() < 0.5;

  /// Very soft elevation — legible on light backgrounds, intentionally
  /// omitted in dark mode (a dark-on-dark shadow just reads as murk; a
  /// hairline border already does the separation job there).
  static List<BoxShadow> cardShadow(ThemeProperties colors) {
    if (_isDark(colors)) return const [];
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Pill-shaped accent chip background — a fixed-alpha tint of [accent]
  /// over the current surface, used by per-action toolbar buttons that each
  /// carry their own [ThemeAccents] color. [filled] pills keep the same
  /// solid accent fill in both themes. Unfilled pills get a brighter tint
  /// plus a stronger flat border in dark mode, since a hairline border reads
  /// as flatter/dimmer against a dark surface than a light one.
  static BoxDecoration accentPill(
    Color accent, {
    required bool filled,
    bool dark = false,
    bool toggle = false,
  }) {
    if (filled) {
      return BoxDecoration(
        color: accent,
        borderRadius: toggle ? ThemeBorders.roundedSm : ThemeBorders.pill,
      );
    }
    return BoxDecoration(
      color: accent.withValues(alpha: dark ? 0.16 : 0.12),
      borderRadius: toggle ? ThemeBorders.roundedSm : ThemeBorders.pill,
      border: Border.all(color: accent.withValues(alpha: dark ? 0.35 : 0.24)),
    );
  }
}
