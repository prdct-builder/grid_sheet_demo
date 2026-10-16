import 'package:flutter/material.dart';

/// A small, curated set of qualitative accent colors for per-action toolbar
/// buttons (`DemoActionButton`/`DemoToggleButton` across `lib/features/`) —
/// e.g. green for an "Insert" action, red for "Delete", indigo for the
/// page's primary action.
///
/// This replaces raw `Colors.blue` / `Colors.deepPurple` / `Colors.brown`
/// etc. sprinkled ad hoc across the 23 feature pages: those are Material's
/// default swatches, tuned for arbitrary app branding rather than each
/// other, so a toolbar using six or seven of them side by side reads as a
/// clashing rainbow. Every color below instead sits at the same
/// lightness/chroma step (roughly Tailwind's 600 step in light mode, 400 in
/// dark mode), so any combination of them reads as one deliberate,
/// harmonious set instead of a random assortment.
///
/// Implemented as a [ThemeExtension] for the same reason as
/// [ThemeProperties]: reachable via `Theme.of(context).extension()`,
/// participates in theme animation, has one light and one dark instance.
@immutable
class ThemeAccents extends ThemeExtension<ThemeAccents> {
  final Color blue;
  final Color indigo;
  final Color teal;
  final Color green;
  final Color red;
  final Color orange;
  final Color deepOrange;
  final Color purple;
  final Color deepPurple;
  final Color pink;
  final Color brown;
  final Color neutral; // grey / blueGrey
  final Color amber; // amber
  final Color yellow;

  const ThemeAccents({
    required this.blue,
    required this.indigo,
    required this.teal,
    required this.green,
    required this.red,
    required this.orange,
    required this.deepOrange,
    required this.purple,
    required this.deepPurple,
    required this.pink,
    required this.brown,
    required this.neutral,
    required this.amber,
    required this.yellow,
  });

  static const light = ThemeAccents(
    blue: Color(0xFF2563EB),
    indigo: Color(0xFF4F46E5),
    teal: Color(0xFF0D9488),
    green: Color(0xFF16A34A),
    red: Color(0xFFDC2626),
    orange: Color(0xFFEA580C),
    deepOrange: Color(0xFFC2410C),
    purple: Color(0xFF9333EA),
    deepPurple: Color(0xFF7C3AED),
    pink: Color(0xFFDB2777),
    brown: Color(0xFF92400E),
    neutral: Color(0xFF475569),
    amber: Color(0xFFD97706),
    yellow: Color(0xFFF59E0B),
  );

  static const dark = ThemeAccents(
    blue: Color(0xFF60A5FA),
    indigo: Color(0xFF818CF8),
    teal: Color(0xFF2DD4BF),
    green: Color(0xFF4ADE80),
    red: Color(0xFFF87171),
    orange: Color(0xFFFB923C),
    deepOrange: Color(0xFFFB7A4A),
    purple: Color(0xFFC084FC),
    deepPurple: Color(0xFFA78BFA),
    pink: Color(0xFFF472B6),
    brown: Color(0xFFD2A66B),
    neutral: Color(0xFF94A3B8),
    amber: Color(0xFFFBBF24),
    yellow: Color(0xFFFACC15),
  );

  @override
  ThemeAccents copyWith({
    Color? blue,
    Color? indigo,
    Color? teal,
    Color? green,
    Color? red,
    Color? orange,
    Color? deepOrange,
    Color? purple,
    Color? deepPurple,
    Color? pink,
    Color? brown,
    Color? neutral,
    Color? amber,
    Color? yellow,
  }) {
    return ThemeAccents(
      blue: blue ?? this.blue,
      indigo: indigo ?? this.indigo,
      teal: teal ?? this.teal,
      green: green ?? this.green,
      red: red ?? this.red,
      orange: orange ?? this.orange,
      deepOrange: deepOrange ?? this.deepOrange,
      purple: purple ?? this.purple,
      deepPurple: deepPurple ?? this.deepPurple,
      pink: pink ?? this.pink,
      brown: brown ?? this.brown,
      neutral: neutral ?? this.neutral,
      amber: amber ?? this.amber,
      yellow: yellow ?? this.yellow,
    );
  }

  @override
  ThemeAccents lerp(ThemeExtension<ThemeAccents>? other, double t) {
    if (other is! ThemeAccents) return this;
    return ThemeAccents(
      blue: Color.lerp(blue, other.blue, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      deepOrange: Color.lerp(deepOrange, other.deepOrange, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      deepPurple: Color.lerp(deepPurple, other.deepPurple, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      brown: Color.lerp(brown, other.brown, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<ThemeAccents>()!`.
extension ThemeAccentsContext on BuildContext {
  ThemeAccents get accents =>
      Theme.of(this).extension<ThemeAccents>() ?? ThemeAccents.light;
}
