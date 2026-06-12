import 'package:flutter/material.dart';

/// Design system color tokens for Planticula.
///
/// The palette is "vibrant & playful": each domain of the app has its own
/// accent color + a soft pastel background, so screens can be "read" by color:
///   - water/watering  -> blue
///   - sun/weather     -> amber
///   - soil/transplant -> orange
///   - pests           -> rose
///   - marketplace     -> purple
abstract class AppColors {
  // ---------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------
  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDeep = Color(0xFF14532D);
  static const Color primarySoft = Color(0xFFDCFCE7);

  // ---------------------------------------------------------------------
  // Domain accents (each with a soft pastel companion)
  // ---------------------------------------------------------------------
  static const Color water = Color(0xFF38BDF8);
  static const Color waterDeep = Color(0xFF0369A1);
  static const Color waterSoft = Color(0xFFE0F2FE);

  static const Color sun = Color(0xFFFBBF24);
  static const Color sunDeep = Color(0xFF92400E);
  static const Color sunSoft = Color(0xFFFEF3C7);

  static const Color soil = Color(0xFFF97316);
  static const Color soilDeep = Color(0xFF9A3412);
  static const Color soilSoft = Color(0xFFFFEDD5);

  static const Color pest = Color(0xFFF43F5E);
  static const Color pestDeep = Color(0xFF9F1239);
  static const Color pestSoft = Color(0xFFFFE4E6);

  static const Color market = Color(0xFFA855F7);
  static const Color marketDeep = Color(0xFF6B21A8);
  static const Color marketSoft = Color(0xFFF3E8FF);

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFE9A23B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFE11D48);
  static const Color errorSoft = Color(0xFFFFE4E6);
  static const Color info = Color(0xFF38BDF8);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // ---------------------------------------------------------------------
  // Neutrals — light
  // ---------------------------------------------------------------------
  static const Color backgroundLight = Color(0xFFFAFDF7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color outlineLight = Color(0xFFE3EBE0);
  static const Color textPrimaryLight = Color(0xFF1A2E22);
  static const Color textSecondaryLight = Color(0xFF5C6F64);

  // ---------------------------------------------------------------------
  // Neutrals — dark
  // ---------------------------------------------------------------------
  static const Color backgroundDark = Color(0xFF0F1A14);
  static const Color surfaceDark = Color(0xFF16241B);
  static const Color outlineDark = Color(0xFF2A3B30);
  static const Color textPrimaryDark = Color(0xFFF0F7F1);
  static const Color textSecondaryDark = Color(0xFF9DB2A4);

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Soft (pastel) container color adapted to brightness. In dark mode the
  /// accent is overlaid at low opacity on the surface instead of pastel.
  static Color softOf(BuildContext context, Color accent, Color soft) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? accent.withValues(alpha: 0.18) : soft;
  }

  /// Readable foreground for content placed on a soft container.
  static Color onSoftOf(BuildContext context, Color deep, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? accent : deep;
  }
}
