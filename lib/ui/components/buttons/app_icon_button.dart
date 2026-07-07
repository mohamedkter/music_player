import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Standardized icon button with optional active state and tooltip.
///
/// Usage:
/// ```dart
/// AppIconButton(
///   icon: Icons.shuffle,
///   isActive: shuffleEnabled,
///   onPressed: onShuffleTap,
///   tooltip: 'Shuffle',
/// )
/// ```
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
    this.size = 24,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Highlights the icon with [activeColor] when true.
  final bool isActive;

  /// Defaults to [AppColors.primary] when active.
  final Color? activeColor;

  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? AppColors.primary)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: size,
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(
          AppColors.hoverFill,
        ),
      ),
    );
  }
}
