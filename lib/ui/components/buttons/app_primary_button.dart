import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Primary filled button following the Studio brutalist design system.
///
/// Features:
/// - 2px solid border
/// - Hard 4px offset shadow (purple)
/// - Press animation: shifts 2px down/right to "meet" the shadow
///
/// Usage:
/// ```dart
/// AppPrimaryButton(
///   label: 'تشغيل الكل',
///   onPressed: () {},
///   icon: Icons.play_arrow,
/// )
/// ```
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// If true, the button stretches to fill available width.
  final bool isExpanded;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: _isPressed
          ? Matrix4.translationValues(2, 2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: isDisabled
            ? AppColors.outline
            : AppColors.primary,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: isDisabled
            ? AppShadows.none
            : (_isPressed ? AppShadows.hardPressed : AppShadows.hardPrimary),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            )
          else ...[
            if (widget.icon != null) ...[
              Icon(widget.icon, color: AppColors.onPrimary, size: 18),
              AppSpacing.hGap(AppSpacing.xs),
            ],
            Text(widget.label, style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onPrimary,
              letterSpacing: 0.5,
            )),
          ],
        ],
      ),
    );

    if (widget.isExpanded) {
      buttonContent = SizedBox(width: double.infinity, child: buttonContent);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: buttonContent,
    );
  }
}
