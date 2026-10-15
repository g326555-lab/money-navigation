import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/spacing.dart';
import '../core/typography.dart';

/// Builds the app theme from tokens only, so no Material default
/// (purple seed, Roboto, ripple, AppBar look) leaks into a screen.
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.surfaceDark,
    onSecondary: AppColors.onSurfaceDark,
    error: AppColors.error,
    onError: AppColors.onSurfaceDark,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.errorText,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceSecondary,
    surfaceContainerHighest: AppColors.surfaceDim,
    outline: AppColors.surfaceDim,
    outlineVariant: AppColors.surfaceDim,
  );

  final textTheme = TextTheme(
    displayLarge: AppTypography.displayXl,
    displayMedium: AppTypography.displayLg,
    headlineMedium: AppTypography.headline,
    titleLarge: AppTypography.title,
    bodyLarge: AppTypography.bodyLg,
    bodyMedium: AppTypography.bodyMd,
    labelLarge: AppTypography.label,
    bodySmall: AppTypography.caption,
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppFonts.latin,
    fontFamilyFallback: AppFonts.latinFallback,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.bodyLg,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: buttonShape,
        textStyle: AppTypography.bodyLg,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
        shape: buttonShape,
        textStyle: AppTypography.bodyLg,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
    ),
  );
}
