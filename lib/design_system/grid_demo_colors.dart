import 'package:flutter/material.dart';

/// Shared color palette for the grid_sheet example demo screens.
///
/// Previously duplicated (with a drifted `headerColor` value) between
/// `demo_gridsheet.dart` and `demo_cell_builder.dart` — consolidated here so
/// both stay in sync.
///
/// Container role hierarchy used by [GridSheetDemo]:
///   - [mainContainerColor]: the outermost page container.
///   - [childContainerColor]: the card nested inside it that wraps the
///     filter panel + grid.
///   - [filterPanelColor]: the filter sidebar inside the child container.
class GridDemoColors {
  // Container role hierarchy (outer -> inner).
  final Color mainContainerColor;
  final Color childContainerColor;
  final Color filterPanelColor;

  // Text/icon colors for content placed directly on [filterPanelColor] /
  // [mainContainerColor] — those are a fixed saturated blue in both themes,
  // so they need light (not textPrimary/textSecondary) foregrounds in both
  // light and dark mode.
  final Color onPrimary;
  final Color onPrimaryMuted;

  final Color gridBackgroundColor;
  final Color headerColor;
  final Color filterColor;
  final Color rowColor;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final Color selectionColor;
  final Color gridBorderColor;
  final Color rowBorderColor;
  final Color columnBorderColor;

  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color linkColor;

  const GridDemoColors({
    required this.mainContainerColor,
    required this.childContainerColor,
    required this.filterPanelColor,
    required this.onPrimary,
    required this.onPrimaryMuted,
    required this.gridBackgroundColor,
    required this.headerColor,
    required this.filterColor,
    required this.rowColor,
    this.evenRowColor,
    this.oddRowColor,
    required this.selectionColor,
    required this.gridBorderColor,
    required this.rowBorderColor,
    required this.columnBorderColor,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.linkColor,
  });

  static const light = GridDemoColors(
    mainContainerColor: Color(0xFF4A63E9),
    childContainerColor: Color(0xFFFFFFFF),
    filterPanelColor: Color(0xFF4A63E9),
    onPrimary: Colors.white,
    onPrimaryMuted: Colors.white70,
    gridBackgroundColor: Color(0xFFFFFFFF), // colorScheme.surface
    headerColor: Color(0xFFEEF0F7), // colorScheme.surfaceContainerHighest
    filterColor: Color(0xFFEAEEFC), // blue-tinted, distinct from headerColor
    rowColor: Color(0xFFFFFFFF), // colorScheme.surface
    selectionColor: Color(0xFFE8ECFB), // primary @ ~10% opacity on white
    gridBorderColor: Color(0xFFE4E7F0), // colorScheme.outlineVariant
    rowBorderColor: Color(0xFFE4E7F0), // colorScheme.outlineVariant
    columnBorderColor: Color(0xFFE4E7F0), // colorScheme.outlineVariant
    primary: Color(0xFF4A63E9),
    textPrimary: Color(0xFF2A2E43),
    textSecondary: Color(0xFF8A8FA3),
    linkColor: Color(0xFF4A63E9),
  );

  static const dark = GridDemoColors(
    // Deep indigo (primary blended into the dark surface) instead of the
    // vivid light-mode primary — a large flat area of full-saturation blue
    // reads harshly in dark mode, so these surfaces get a darkened tint
    // while buttons/accents (`primary` below) stay at full saturation.
    mainContainerColor: Color(0xFF2E3A76),
    childContainerColor: Color(0xFF1C1E2A),
    filterPanelColor: Color(0xFF2E3A76),
    onPrimary: Colors.white,
    onPrimaryMuted: Colors.white70,
    gridBackgroundColor: Color(0xFF1C1E2A), // colorScheme.surface
    headerColor: Color(0xFF262938), // colorScheme.surfaceContainerHighest
    filterColor: Color(0xFF262E4D), // blue-tinted, distinct from headerColor
    rowColor: Color(0xFF1C1E2A), // colorScheme.surface
    evenRowColor: Color(0xFF20222F), // colorScheme.surfaceContainerLow
    oddRowColor: Color(0xFF1C1E2A), // colorScheme.surface
    selectionColor: Color(0xFF252C50), // primary @ ~20% opacity on dark
    gridBorderColor: Color(0xFF3A3D4F), // colorScheme.outlineVariant
    rowBorderColor: Color(0xFF3A3D4F), // colorScheme.outlineVariant
    columnBorderColor: Color(0xFF3A3D4F), // colorScheme.outlineVariant
    primary: Color(0xFF4A63E9),
    textPrimary: Color(0xFFEDEEF5),
    textSecondary: Color(0xFF9A9DB5),
    linkColor: Color(0xFF8FA0FF),
  );
}
