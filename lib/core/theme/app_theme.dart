import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Planticula theme — "vibrant & playful" design system.
///
/// Flat surfaces (no hard shadows), big rounded corners, pill buttons and
/// Poppins typography. Color tokens live in [AppColors], spacing/radius
/// tokens in [AppDimens].
class AppTheme {
  static const String fontFamily = 'Poppins';

  // Kept as aliases so legacy references keep working.
  static const Color primaryColor = AppColors.primary;
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color success = AppColors.success;
  static const Color info = AppColors.info;

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final outline = isDark ? AppColors.outlineDark : AppColors.outlineLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.primarySoft,
      onPrimaryContainer: isDark ? AppColors.primarySoft : AppColors.primaryDeep,
      secondary: AppColors.water,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? AppColors.water.withValues(alpha: 0.18)
          : AppColors.waterSoft,
      onSecondaryContainer: isDark ? AppColors.waterSoft : AppColors.waterDeep,
      tertiary: AppColors.sun,
      onTertiary: AppColors.sunDeep,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: isDark
          ? AppColors.error.withValues(alpha: 0.18)
          : AppColors.errorSoft,
      onErrorContainer: isDark ? AppColors.errorSoft : AppColors.pestDeep,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: background,
      onSurfaceVariant: textSecondary,
      outline: outline,
      outlineVariant: outline,
      shadow: Colors.black.withValues(alpha: 0.08),
    );

    final textTheme = _textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.headlineMedium,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.cardRadius,
          side: BorderSide(color: outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
          shape: RoundedRectangleBorder(borderRadius: AppDimens.buttonRadius),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
          shape: RoundedRectangleBorder(borderRadius: AppDimens.buttonRadius),
          textStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
          shape: RoundedRectangleBorder(borderRadius: AppDimens.buttonRadius),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          textStyle: textTheme.titleLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.lg,
            vertical: AppDimens.sm,
          ),
          foregroundColor: AppColors.primary,
          textStyle: textTheme.titleLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        extendedTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: isDark
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.primarySoft,
        labelStyle: textTheme.bodyMedium,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusChip),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: surface,
        indicatorColor: isDark
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.bodySmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? (isDark ? AppColors.primarySoft : AppColors.primaryDeep)
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (isDark ? AppColors.primarySoft : AppColors.primaryDeep)
                : textSecondary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppDimens.inputRadius,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.inputRadius,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.inputRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimens.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg,
          vertical: AppDimens.lg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.sheetRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryDeep,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.buttonRadius),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? AppColors.primarySoft : AppColors.primaryDeep,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.titleLarge,
        unselectedLabelStyle: textTheme.bodyLarge,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppDimens.buttonRadius),
        iconColor: textSecondary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primarySoft,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : outline,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      // Big numbers used as graphic elements (temperature, ml, days).
      displayLarge: TextStyle(
          fontSize: 40, fontWeight: FontWeight.w700, color: primary, height: 1.1),
      displayMedium: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, color: primary, height: 1.1),
      displaySmall: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700, color: primary, height: 1.15),
      headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 15, color: primary),
      bodyMedium: TextStyle(fontSize: 14, color: primary),
      bodySmall: TextStyle(fontSize: 12, color: secondary),
      labelLarge: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: primary),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
