import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography tokens from the Studio Light design system.
///
/// Three font families:
/// - **Syne** → Headlines (avant-garde, structural)
/// - **HankenGrotesk** → Body text (legible, contemporary)
/// - **JetBrainsMono** → Labels, metadata, technical details
abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Syne',
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.02 * 72,
    color: AppColors.onSurface,
  );

  static const TextStyle displayLgMobile = TextStyle(
    fontFamily: 'Syne',
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.02 * 48,
    color: AppColors.onSurface,
  );

  // ── Headline ──────────────────────────────────────────────────────────────
  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Syne',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: 'Syne',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Syne',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: 'Syne',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.onSurface,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'HankenGrotesk',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'HankenGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'HankenGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  // ── Label (Mono) ──────────────────────────────────────────────────────────
  static const TextStyle labelMd = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.05 * 14,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.05 * 12,
    color: AppColors.onSurfaceVariant,
  );

  // ── Convenience methods ───────────────────────────────────────────────────

  /// Returns [headlineMd] with a custom [color].
  static TextStyle headlineMdColored(Color color) =>
      headlineMd.copyWith(color: color);

  /// Returns [bodyMd] with a custom [color].
  static TextStyle bodyMdColored(Color color) =>
      bodyMd.copyWith(color: color);

  /// Returns [labelSm] for chip/badge text.
  static TextStyle badgeLabel({Color color = AppColors.onSurface}) =>
      labelSm.copyWith(color: color);
}
