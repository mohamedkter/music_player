import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../buttons/app_primary_button.dart';

/// Empty state illustration widget.
///
/// Usage:
/// ```dart
/// AppEmptyState(
///   icon: Icons.library_music_outlined,
///   title: 'No Music Found',
///   message: 'Tap the button below to scan your device.',
///   actionLabel: 'Scan Now',
///   onAction: () => bloc.add(ScanLibrary()),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                border: Border.all(color: AppColors.outlineVariant, width: 2),
              ),
              child: Center(
                child: Icon(icon, size: 48, color: AppColors.outline),
              ),
            ),
            AppSpacing.vGap(AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.headlineSm,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.vGap(AppSpacing.sm),
              Text(
                message!,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.vGap(AppSpacing.lg),
              AppPrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
