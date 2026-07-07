import 'package:flutter/material.dart';

/// Studio Light design system color tokens.
/// All colors are defined here as a single source of truth.
/// Screens and widgets must reference these — never use raw hex values.
abstract final class AppColors {
  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6240C9);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF7B5BE4);
  static const Color onPrimaryContainer = Color(0xFFFFF9FF);
  static const Color inversePrimary = Color(0xFFCCBDFF);

  // ── Primary Fixed ─────────────────────────────────────────────────────────
  static const Color primaryFixed = Color(0xFFE7DEFF);
  static const Color primaryFixedDim = Color(0xFFCCBDFF);
  static const Color onPrimaryFixed = Color(0xFF1F005F);
  static const Color onPrimaryFixedVariant = Color(0xFF4D26B4);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF705D00);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFCD400);
  static const Color onSecondaryContainer = Color(0xFF6E5C00);

  // ── Secondary Fixed ───────────────────────────────────────────────────────
  static const Color secondaryFixed = Color(0xFFFFE16D);
  static const Color secondaryFixedDim = Color(0xFFE9C400);
  static const Color onSecondaryFixed = Color(0xFF221B00);
  static const Color onSecondaryFixedVariant = Color(0xFF544600);

  // ── Tertiary ──────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF5B5A5C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF747374);
  static const Color onTertiaryContainer = Color(0xFFFDFAFB);

  // ── Tertiary Fixed ────────────────────────────────────────────────────────
  static const Color tertiaryFixed = Color(0xFFE5E2E3);
  static const Color tertiaryFixedDim = Color(0xFFC8C6C7);
  static const Color onTertiaryFixed = Color(0xFF1B1B1C);
  static const Color onTertiaryFixedVariant = Color(0xFF474647);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Surface / Background ──────────────────────────────────────────────────
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF494554);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);

  // ── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF7A7585);
  static const Color outlineVariant = Color(0xFFCAC4D6);

  // ── Surface Tint ──────────────────────────────────────────────────────────
  static const Color surfaceTint = Color(0xFF6543CD);

  // ── Semantic shortcuts ────────────────────────────────────────────────────
  /// Used for borders on interactive elements (brutalist 2px stroke).
  static const Color border = Color(0xFF1A1C1C);

  /// Gold accent — badges, win states, highlights.
  static const Color gold = Color(0xFFFCD400);

  /// Hover / focus fill on list items.
  static const Color hoverFill = Color(0xFFF0EDFF);

  /// Hard shadow color (primary-tinted).
  static const Color shadowPrimary = Color(0xFF4D26B4);

  /// Hard shadow color (neutral).
  static const Color shadowNeutral = Color(0xFF1A1C1C);
}
