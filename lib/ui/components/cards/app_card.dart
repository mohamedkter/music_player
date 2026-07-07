import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Base card component — white surface, 2px border, hard shadow.
///
/// This is the foundational container for content grouping.
/// Wrap any content in [AppCard] to apply consistent elevation treatment.
///
/// Usage:
/// ```dart
/// AppCard(
///   onTap: () {},
///   child: SongListItem(song: song),
/// )
/// ```
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.hasShadow = true,
    this.shadowType = _ShadowType.neutral,
  });

  /// Convenience constructor with primary (purple) shadow.
  const AppCard.primary({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.hasShadow = true,
  }) : shadowType = _ShadowType.primary;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool hasShadow;
  final _ShadowType shadowType;

  @override
  State<AppCard> createState() => _AppCardState();
}

enum _ShadowType { neutral, primary }

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  List<BoxShadow> get _shadow {
    if (!widget.hasShadow) return AppShadows.none;
    if (_isPressed) return AppShadows.hardPressed;
    return widget.shadowType == _ShadowType.primary
        ? AppShadows.hardPrimary
        : AppShadows.hardNeutral;
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _isPressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: _shadow,
        ),
        padding: widget.padding ?? AppSpacing.cardPadding,
        child: widget.child,
      ),
    );
  }
}
