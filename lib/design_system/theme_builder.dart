import 'package:flutter/material.dart';

import 'theme_accents.dart';
import 'theme_properties.dart';
import 'theme_typography.dart';

/// Builds the full [ThemeData] for the requested [brightness] from the
/// design tokens in this folder — the single place that turns
/// [ThemeProperties]/[ThemeAccents]/[TextTypography] into something
/// `MaterialApp.theme`/`darkTheme` can consume.
///
/// Every [ColorScheme] role is mapped explicitly from [ThemeProperties]
/// rather than derived via [ColorScheme.fromSeed] — the M3 seed algorithm
/// invents its own secondary/tertiary hues and a `surfaceTint` overlay that
/// would fight the flat slate surfaces defined here. `surfaceTint` is set to
/// transparent so elevated surfaces stay flat instead of picking up a tint.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? ThemeProperties.dark : ThemeProperties.light;
  final accents = isDark ? ThemeAccents.dark : ThemeAccents.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.primarySubtleBg,
    onPrimaryContainer: colors.primarySubtleFg,
    secondary: colors.primary,
    onSecondary: colors.onPrimary,
    secondaryContainer: colors.surfaceSubtle,
    onSecondaryContainer: colors.textPrimary,
    tertiary: colors.info,
    onTertiary: Colors.white,
    tertiaryContainer: colors.infoSubtleBg,
    onTertiaryContainer: colors.info,
    error: colors.danger,
    onError: Colors.white,
    errorContainer: colors.dangerSubtleBg,
    onErrorContainer: colors.danger,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.border,
    outlineVariant: colors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: colors.textPrimary,
    onInverseSurface: colors.canvas,
    inversePrimary: colors.primary,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: colors.canvas,
    surfaceContainerLow: colors.surfaceSubtle,
    surfaceContainer: colors.surfaceSubtle,
    surfaceContainerHigh: colors.surfaceHover,
    surfaceContainerHighest: colors.surfaceHover,
    surfaceDim: colors.surfaceSubtle,
    surfaceBright: colors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: TextTypography.fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.canvas,
    cardColor: colors.surface,
    dividerColor: colors.border,
    splashFactory: InkSparkle.splashFactory,
    tooltipTheme: TooltipThemeData(
      textStyle: TextTypography.caption.copyWith(
        color: isDark ? colors.onSurfaceInverse : Colors.white,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.grey[700]!.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextTypography.body.copyWith(color: colors.canvas),
    ),
    extensions: [colors, accents],
  );
}
