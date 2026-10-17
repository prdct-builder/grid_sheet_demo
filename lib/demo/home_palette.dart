import 'package:flutter/material.dart';

/// Color palette built specifically for [DemoHomePage] and [DemoCard] — not
/// the shared `design_system/theme_properties.dart` tokens used by the 23
/// feature pages.
///
/// Flat and neutral by design: every surface, border, shadow, and text
/// color is true (untinted) gray — [primary] is the *only* hue anywhere in
/// this palette, reserved for the brand accent (icons, links, focus/hover
/// borders). No color bleeds into backgrounds, and there is no gradient
/// ("glossy") fill anywhere — [cardIconBg] is a single flat color.
///
/// Structural tokens that aren't colors — [ThemeBorders]' radius scale,
/// [TextTypography]'s type scale — are still shared with the rest of the
/// app for rhythm consistency; only the color roles are local to this file.
@immutable
class HomePalette {
  // ---- Background ----
  final Color canvas;

  // ---- Text ----
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color eyebrow;

  // ---- Brand accent (the only hue in this palette) ----
  final Color primary;
  final Color primaryHover;

  // ---- Hero icon tint ----
  final Color heroIconFg;

  // ---- Search field ----
  final Color searchBg;
  final Color searchBorder;
  final Color searchBorderFocus;
  final Color searchIcon;

  // ---- Theme toggle button ----
  final Color toggleBg;
  final Color toggleBorder;
  final Color toggleIcon;

  // ---- Card ----
  final Color cardSurface;
  final Color cardBorder;
  final Color cardBorderHover;
  final Color cardShadowAmbient; // Neutral shadow tint, rest and hover alike.
  final Color cardIconBg; // Flat — no gradient.
  final Color footerLink;
  final Color footerLinkHover;

  // ---- Empty search state ----
  final Color emptyStateBg;
  final Color emptyStateIcon;

  // ---- Glass surfaces ----
  final Color glassSurface;
  final Color glassBorder;
  final Color glassHighlight;
  final Color glassShadow;

  const HomePalette({
    required this.canvas,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.eyebrow,
    required this.primary,
    required this.primaryHover,
    required this.heroIconFg,
    required this.searchBg,
    required this.searchBorder,
    required this.searchBorderFocus,
    required this.searchIcon,
    required this.toggleBg,
    required this.toggleBorder,
    required this.toggleIcon,
    required this.cardSurface,
    required this.cardBorder,
    required this.cardBorderHover,
    required this.cardShadowAmbient,
    required this.cardIconBg,
    required this.footerLink,
    required this.footerLinkHover,
    required this.emptyStateBg,
    required this.emptyStateIcon,
    required this.glassSurface,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassShadow,
  });

  /// Neutral flat light palette with subtle depth.
  /// White cards on a soft gray canvas and a restrained violet accent.
  static final light = HomePalette(
    canvas: Color(0xFFF5F7FA),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    eyebrow: Color(0xFF4F46E5),
    primary: Color(0xFF4F46E5),
    primaryHover: Color(0xFF4338CA),
    heroIconFg: Color(0xFF4F46E5),
    searchBg: Color(0xFFFFFFFF),
    searchBorder: Color(0xFFE5E7EB),
    searchBorderFocus: Color(0xFF4F46E5),
    searchIcon: Color(0xFF9CA3AF),
    toggleBg: Color(0xFFFFFFFF),
    toggleBorder: Color(0xFFE5E7EB),
    toggleIcon: Color(0xFF6B7280),
    cardSurface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E7EB),
    cardBorderHover: Color(0xFF4F46E5),
    cardShadowAmbient: Color(0xFF111827),
    cardIconBg: Color(0xFFF3F4F6),
    footerLink: Color(0xFF4F46E5),
    footerLinkHover: Color(0xFF4338CA),
    emptyStateBg: Color(0xFFF3F4F6),
    emptyStateIcon: Color(0xFF9CA3AF),
    glassSurface: Color(0xFFFFFFFF).withValues(alpha: 0.55),
    glassBorder: Color(0xFFFFFFFF).withValues(alpha: 0.6),
    glassHighlight: Color(0xFFFFFFFF).withValues(alpha: 0.35),
    glassShadow: const Color(0xFF1F2937).withValues(alpha: 0.10),
  );

  /// Dark palette — every surface that sits on top of [canvas] (search
  /// field, theme toggle, dashboard cards) is a flat opaque step up from the
  /// near-black canvas rather than a translucent white-alpha tint. These are
  /// pre-baked to the color that alpha tint would have composited to at
  /// rest, so the resting look is unchanged — but being opaque, an
  /// `AnimatedContainer` interpolating a surface from [light] to [dark] now
  /// does a plain RGB fade instead of an alpha fade. An alpha fade ramps
  /// down from fully opaque while [canvas] has *already* snapped instantly
  /// to its dark value (theme swaps aren't animated), so for a few frames a
  /// near-opaque white shape would sit on an already-dark background — a
  /// visible white flash — before settling. The violet accent stays fully
  /// saturated — unchanged from the previous flat palette.
  static final dark = HomePalette(
    canvas: const Color(0xFF05070D),
    textPrimary: const Color(0xFFF9FAFB),
    textSecondary: const Color(0xFFD1D5DB),
    textMuted: const Color(0xFF9CA3AF),
    eyebrow: const Color(0xFF818CF8),
    primary: const Color(0xFF818CF8),
    primaryHover: const Color(0xFFA5B4FC),
    heroIconFg: const Color(0xFF818CF8),
    searchBg: const Color(0xFF1F2026),
    searchBorder: const Color(0xFF2A2C31),
    searchBorderFocus: const Color(0xFF818CF8),
    searchIcon: const Color(0xFF9CA3AF),
    toggleBg: const Color(0xFF1F2026),
    toggleBorder: const Color(0xFF2A2C31),
    toggleIcon: const Color(0xFFD1D5DB),
    cardSurface: const Color(0xFF23252A),
    cardBorder: const Color(0xFF2D2F34),
    cardBorderHover: const Color(0xFF818CF8),
    cardShadowAmbient: const Color(0xFF000000),
    cardIconBg: const Color(0xFF282A2F),
    footerLink: const Color(0xFF818CF8),
    footerLinkHover: const Color(0xFFA5B4FC),
    emptyStateBg: const Color(0xFF23252A),
    emptyStateIcon: const Color(0xFF9CA3AF),
    glassSurface: const Color(0xFF23252A).withValues(alpha: 0.45),
    glassBorder: const Color(0xFFFFFFFF).withValues(alpha: 0.10),
    glassHighlight: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
    glassShadow: const Color(0xFF000000).withValues(alpha: 0.35),
  );

  /// Resolves against the app's current [ThemeData.brightness] — the same
  /// signal `MaterialApp.theme`/`darkTheme` switch on via `appThemeMode`, so
  /// this palette always matches the app-wide light/dark toggle without
  /// depending on the shared `ThemeProperties` tokens.
  static HomePalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
