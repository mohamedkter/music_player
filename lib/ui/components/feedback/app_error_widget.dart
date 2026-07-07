import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../buttons/app_primary_button.dart';

/// Full-page error state widget.
///
/// Shown when a BLoC emits an error state. Provides a retry action.
///
/// Usage:
/// ```dart
/// AppErrorWidget(
///   message: state.failure.message,
///   onRetry: () => bloc.add(RetryEvent()),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                border: Border.all(color: AppColors.error, width: 2),
              ),
              child: Icon(icon, size: 40, color: AppColors.error),
            ),
            AppSpacing.vGap(AppSpacing.md),
            Text(
              'Something went wrong',
              style: AppTextStyles.headlineSm,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap(AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.vGap(AppSpacing.lg),
              AppPrimaryButton(label: 'Retry', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
