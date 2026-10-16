import 'package:flutter/material.dart';

/// Corner-radius and stroke-width scale shared by every feature page's
/// chrome (cards, pills, chips, inputs).
abstract final class ThemeBorders {
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusPill = 999;

  static const double hairline = 1;
  static const double thick = 1.5;

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(radiusPill));
}
