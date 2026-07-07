import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Full-page loading indicator.
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            AppSpacing.vGap(AppSpacing.md),
            Text(
              message!,
              style: AppTextStyles.labelMd,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline shimmer-style skeleton loader for list items.
class SongListItemSkeleton extends StatefulWidget {
  const SongListItemSkeleton({super.key});

  @override
  State<SongListItemSkeleton> createState() => _SongListItemSkeletonState();
}

class _SongListItemSkeletonState extends State<SongListItemSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: _buildSkeleton(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: AppSpacing.listItemPadding,
      child: Row(
        children: [
          _box(48, 48),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(double.infinity, 14),
                AppSpacing.vGap(AppSpacing.xs),
                _box(120, 10),
              ],
            ),
          ),
          AppSpacing.hGap(AppSpacing.md),
          _box(36, 10),
        ],
      ),
    );
  }

  Widget _box(double w, double h) => Container(
        width: w,
        height: h,
        color: AppColors.surfaceContainerHigh,
      );
}
