import 'package:flutter/material.dart';

/// Core color-role tokens for the demo app's chrome — everything that isn't
/// the grid itself (page background, cards, toolbars, status text, semantic
/// success/warning/danger states).
///
/// Palette family: a cool "slate" neutral scale (the same neutral family
/// used by Linear/Vercel/GitHub-style dashboards) paired with an indigo
/// accent — chosen over a plain Material blue seed because it reads as a
/// deliberate brand color rather than a framework default, while staying
/// legible and professional for an app that's mostly text/data density.
///
/// Implemented as a [ThemeExtension] (rather than a plain static class) so
/// it participates in Flutter's normal theme animation/lerp and is reachable
/// via `Theme.of(context).extension<ThemeProperties>()!` from anywhere,
/// exactly like the built-in [ColorScheme].
@immutable
class ThemeProperties extends ThemeExtension<ThemeProperties> {
  // ---- Surfaces (elevation layers, lightest/outermost to none) ----
  final Color canvas; // Scaffold background, behind every card.
  final Color surface; // Cards, the grid itself, dialogs.
  final Color surfaceSubtle; // Toolbars, status bars, table headers.
  final Color surfaceHover; // Hover/pressed state over a surface.
  final Color surfaceSelected; // Selected list/card state.

  // ---- Borders ----
  final Color border; // Default hairline border/divider.
  final Color borderStrong; // Emphasized border (focus container, hr).

  // ---- Text ----
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color
      onSurfaceInverse; // Text on a dark chip/status bar in light mode etc.

  // ---- Brand accent ----
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;
  final Color primarySubtleBg;
  final Color primarySubtleFg;

  // ---- Semantic states ----
  final Color success;
  final Color successSubtleBg;
  final Color warning;
  final Color warningSubtleBg;
  final Color danger;
  final Color dangerSubtleBg;
  final Color info;
  final Color infoSubtleBg;

  const ThemeProperties({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceHover,
    required this.surfaceSelected,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onSurfaceInverse,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.primarySubtleBg,
    required this.primarySubtleFg,
    required this.success,
    required this.successSubtleBg,
    required this.warning,
    required this.warningSubtleBg,
    required this.danger,
    required this.dangerSubtleBg,
    required this.info,
    required this.infoSubtleBg,
  });

  /// Light theme ("Daylight") — slate-50/white surfaces, slate-900 ink.
  static const light = ThemeProperties(
    canvas: Color(0xFFF8FAFC), // slate-50
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF1F5F9), // slate-100
    surfaceHover: Color(0xFFE2E8F0), // slate-200
    surfaceSelected: Color(0xFFEEF2FF), // indigo-50
    border: Color(0xFFE2E8F0), // slate-200
    borderStrong: Color(0xFFCBD5E1), // slate-300
    textPrimary: Color(0xFF0F172A), // slate-900
    textSecondary: Color(0xFF64748B), // slate-500
    textMuted: Color(0xFF94A3B8), // slate-400
    onSurfaceInverse: Color(0xFFF8FAFC),
    primary: Color(0xFF4F46E5), // indigo-600
    primaryHover: Color(0xFF4338CA), // indigo-700
    onPrimary: Color(0xFFFFFFFF),
    primarySubtleBg: Color(0xFFEEF2FF), // indigo-50
    primarySubtleFg: Color(0xFF4338CA), // indigo-700
    success: Color(0xFF059669), // emerald-600
    successSubtleBg: Color(0xFFECFDF5), // emerald-50
    warning: Color(0xFFD97706), // amber-600
    warningSubtleBg: Color(0xFFFFFBEB), // amber-50
    danger: Color(0xFFDC2626), // red-600
    dangerSubtleBg: Color(0xFFFEF2F2), // red-50
    info: Color(0xFF0284C7), // sky-600
    infoSubtleBg: Color(0xFFF0F9FF), // sky-50
  );

  /// Dark theme — a deep near-black blue-tinted base, cooler/richer surface
  /// steps than the old flat slate scale, softened (not pure white) ink, and
  /// accents lifted a step lighter than their light-mode value so they stay
  /// legible against a dark background.
  static const dark = ThemeProperties(
    canvas: Color(0xFF05070D),
    surface: Color(0xFF13141F),
    surfaceSubtle: Color(0xFF191B2A),
    surfaceHover: Color(0xFF212437),
    surfaceSelected: Color(0xFF20244D),
    border: Color(0xFF2C2F42),
    borderStrong: Color(0xFF3B3F56),
    textPrimary: Color(0xFFEDEFF7),
    textSecondary: Color(0xFFA3ABC2),
    textMuted: Color(0xFF747C99),
    onSurfaceInverse: Color(0xFF0F172A),
    primary: Color(0xFF818CF8), // indigo-400
    primaryHover: Color(0xFFA5B4FC), // indigo-300
    onPrimary: Color(0xFF10131C),
    primarySubtleBg: Color(0xFF23255A),
    primarySubtleFg: Color(0xFFA5B4FC),
    success: Color(0xFF34D399), // emerald-400
    successSubtleBg: Color(0xFF0F2A22),
    warning: Color(0xFFFBBF24), // amber-400
    warningSubtleBg: Color(0xFF2A2210),
    danger: Color(0xFFF87171), // red-400
    dangerSubtleBg: Color(0xFF2A1414),
    info: Color(0xFF38BDF8), // sky-400
    infoSubtleBg: Color(0xFF0C2430),
  );

  @override
  ThemeProperties copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceHover,
    Color? surfaceSelected,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? onSurfaceInverse,
    Color? primary,
    Color? primaryHover,
    Color? onPrimary,
    Color? primarySubtleBg,
    Color? primarySubtleFg,
    Color? success,
    Color? successSubtleBg,
    Color? warning,
    Color? warningSubtleBg,
    Color? danger,
    Color? dangerSubtleBg,
    Color? info,
    Color? infoSubtleBg,
  }) {
    return ThemeProperties(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onSurfaceInverse: onSurfaceInverse ?? this.onSurfaceInverse,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySubtleBg: primarySubtleBg ?? this.primarySubtleBg,
      primarySubtleFg: primarySubtleFg ?? this.primarySubtleFg,
      success: success ?? this.success,
      successSubtleBg: successSubtleBg ?? this.successSubtleBg,
      warning: warning ?? this.warning,
      warningSubtleBg: warningSubtleBg ?? this.warningSubtleBg,
      danger: danger ?? this.danger,
      dangerSubtleBg: dangerSubtleBg ?? this.dangerSubtleBg,
      info: info ?? this.info,
      infoSubtleBg: infoSubtleBg ?? this.infoSubtleBg,
    );
  }

  @override
  ThemeProperties lerp(ThemeExtension<ThemeProperties>? other, double t) {
    if (other is! ThemeProperties) return this;
    return ThemeProperties(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      onSurfaceInverse:
          Color.lerp(onSurfaceInverse, other.onSurfaceInverse, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySubtleBg: Color.lerp(primarySubtleBg, other.primarySubtleBg, t)!,
      primarySubtleFg: Color.lerp(primarySubtleFg, other.primarySubtleFg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtleBg: Color.lerp(successSubtleBg, other.successSubtleBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtleBg: Color.lerp(warningSubtleBg, other.warningSubtleBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSubtleBg: Color.lerp(dangerSubtleBg, other.dangerSubtleBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSubtleBg: Color.lerp(infoSubtleBg, other.infoSubtleBg, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<ThemeProperties>()!`.
extension ThemePropertiesContext on BuildContext {
  ThemeProperties get colors =>
      Theme.of(this).extension<ThemeProperties>() ?? ThemeProperties.light;
}
