import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds [ThemeData] for the Studio Light design system.
///
/// Single entry point — features/screens only need to call
/// `AppTheme.light()` or `AppTheme.dark()`.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = isLight ? _lightColorScheme : _darkColorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.surfaceContainerHigh : const Color(0xFF121212),

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineMd.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // ── Text ───────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(colorScheme.onSurface),

      // ── Input ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colorScheme.outline, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 2,
        space: 0,
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        labelStyle: AppTextStyles.labelSm,
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Icon ───────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),

      // ── Slider ─────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        inactiveTrackColor: colorScheme.outlineVariant,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }

  // ── Color Schemes ─────────────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceTint: AppColors.surfaceTint,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.inversePrimary,
    onPrimary: AppColors.onPrimaryFixed,
    primaryContainer: AppColors.onPrimaryFixedVariant,
    onPrimaryContainer: AppColors.primaryFixed,
    secondary: AppColors.secondaryFixedDim,
    onSecondary: AppColors.onSecondaryFixed,
    secondaryContainer: AppColors.onSecondaryFixedVariant,
    onSecondaryContainer: AppColors.secondaryFixed,
    tertiary: AppColors.tertiaryFixedDim,
    onTertiary: AppColors.onTertiaryFixed,
    tertiaryContainer: AppColors.onTertiaryFixedVariant,
    onTertiaryContainer: AppColors.tertiaryFixed,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFE2E2E2),
    surfaceContainerLowest: Color(0xFF0D0D0D),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF1E1E1E),
    surfaceContainerHigh: Color(0xFF242424),
    surfaceContainerHighest: Color(0xFF2A2A2A),
    onSurfaceVariant: Color(0xFFCAC4D6),
    outline: Color(0xFF958FA6),
    outlineVariant: Color(0xFF494554),
    inverseSurface: AppColors.surfaceContainerHighest,
    onInverseSurface: AppColors.onSurface,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.inversePrimary,
  );

  // ── Text Theme ────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color defaultColor) {
    TextStyle apply(TextStyle s) => s.copyWith(color: defaultColor);

    return TextTheme(
      displayLarge: apply(AppTextStyles.displayLg),
      headlineLarge: apply(AppTextStyles.headlineLg),
      headlineMedium: apply(AppTextStyles.headlineMd),
      headlineSmall: apply(AppTextStyles.headlineSm),
      bodyLarge: apply(AppTextStyles.bodyLg),
      bodyMedium: apply(AppTextStyles.bodyMd),
      bodySmall: apply(AppTextStyles.bodySm),
      labelLarge: apply(AppTextStyles.labelMd),
      labelSmall: apply(AppTextStyles.labelSm),
    );
  }
}
