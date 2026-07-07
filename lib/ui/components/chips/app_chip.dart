import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Chip / Badge variant enum.
enum AppChipVariant {
  /// Gold fill — high-priority labels, "win" states.
  gold,

  /// Dark fill with white text — standard tags.
  dark,

  /// Primary purple fill — active/selected state.
  primary,

  /// Outlined only — secondary information.
  outlined,
}

/// Studio-branded chip/badge component.
///
/// Uses JetBrains Mono (label-sm) for that workspace / draft aesthetic.
///
/// Usage:
/// ```dart
/// AppChip(label: '320 kbps', variant: AppChipVariant.gold)
/// AppChip(label: 'FLAC',     variant: AppChipVariant.dark)
/// AppChip(label: '12 songs', variant: AppChipVariant.outlined)
/// ```
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.outlined,
    this.onTap,
  });

  final String label;
  final AppChipVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, borderColor) = _resolveColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.chipPadding,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.badgeLabel(color: fg),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color border) _resolveColors() {
    return switch (variant) {
      AppChipVariant.gold => (
          AppColors.gold,
          AppColors.onSecondaryFixed,
          AppColors.border,
        ),
      AppChipVariant.dark => (
          AppColors.border,
          Colors.white,
          AppColors.border,
        ),
      AppChipVariant.primary => (
          AppColors.primary,
          AppColors.onPrimary,
          AppColors.primary,
        ),
      AppChipVariant.outlined => (
          Colors.transparent,
          AppColors.onSurfaceVariant,
          AppColors.outline,
        ),
    };
  }
}
