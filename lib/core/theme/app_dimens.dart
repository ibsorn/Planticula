import 'package:flutter/material.dart';

/// Spacing, radius and sizing tokens (4pt scale).
abstract class AppDimens {
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Radii
  static const double radiusCard = 20;
  static const double radiusButton = 16;
  static const double radiusInput = 16;
  static const double radiusSheet = 24;
  static const double radiusChip = 100; // full pill

  static BorderRadius get cardRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get buttonRadius => BorderRadius.circular(radiusButton);
  static BorderRadius get inputRadius => BorderRadius.circular(radiusInput);
  static BorderRadius get sheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(radiusSheet));

  // Common paddings
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
