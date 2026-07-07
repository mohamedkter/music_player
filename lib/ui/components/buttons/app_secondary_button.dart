import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Secondary outlined button — white fill with black border + hard shadow.
///
/// Usage:
/// ```dart
/// AppSecondaryButton(label: 'Shuffle', icon: Icons.shuffle, onPressed: () {})
/// ```
class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;

    Widget btn = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: _isPressed
          ? Matrix4.translationValues(2, 2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow:
            _isPressed ? AppShadows.hardPressed : AppShadows.hardNeutral,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: AppColors.onSurface, size: 18),
            AppSpacing.hGap(AppSpacing.xs),
          ],
          Text(
            widget.label,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );

    if (widget.isExpanded) {
      btn = SizedBox(width: double.infinity, child: btn);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: btn,
    );
  }
}
