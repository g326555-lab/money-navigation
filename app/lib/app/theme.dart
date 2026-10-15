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
    displayLarge: AppTypography.english.displayXl,
    displayMedium: AppTypography.english.displayLg,
    headlineMedium: AppTypography.english.headline,
    titleLarge: AppTypography.english.title,
    bodyLarge: AppTypography.english.bodyLg,
    bodyMedium: AppTypography.english.bodyMd,
    labelLarge: AppTypography.english.label,
    bodySmall: AppTypography.english.caption,
  );

  final buttonShape = RoundedSuperellipseBorder(
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
      titleTextStyle: AppTypography.english.bodyLg,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: buttonShape,
        textStyle: AppTypography.english.bodyLg,
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        minimumSize: const Size(
          AppSizes.minTouchTarget,
          AppSizes.minTouchTarget,
        ),
        shape: buttonShape,
        textStyle: AppTypography.english.bodyLg,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: AppTypography.english.label.copyWith(
        color: AppColors.onSurfaceDark,
      ),
      actionTextColor: AppColors.primaryOnDark,
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        0,
        AppSpacing.screenMargin,
        // The Scaffold already lifts a floating bar above the tab bar.
        AppSpacing.md,
      ),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
      dragHandleColor: AppColors.handle,
      dragHandleSize: Size(
        AppSizes.sheetHandleWidth,
        AppSizes.sheetHandleHeight,
      ),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
  );
}
