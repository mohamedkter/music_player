import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../bloc/songs_bloc.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSelected,
  });

  final SongSortOption currentSort;
  final ValueChanged<SongSortOption> onSelected;

  static const _options = [
    (SongSortOption.titleAsc, 'Title A→Z', Icons.sort_by_alpha),
    (SongSortOption.titleDesc, 'Title Z→A', Icons.sort_by_alpha),
    (SongSortOption.artistAsc, 'Artist', Icons.person_outline),
    (SongSortOption.albumAsc, 'Album', Icons.album_outlined),
    (SongSortOption.dateNewest, 'Date Added (Newest)', Icons.calendar_today),
    (SongSortOption.dateOldest, 'Date Added (Oldest)', Icons.calendar_today),
    (SongSortOption.durationLongest, 'Duration (Longest)', Icons.timer_outlined),
    (SongSortOption.durationShortest, 'Duration (Shortest)', Icons.timer_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 2),
          left: BorderSide(color: AppColors.border, width: 2),
          right: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('Sort by', style: AppTextStyles.headlineSm),
          ),
          const Divider(height: 0),
          ..._options.map(
            (opt) => _SortOption(
              label: opt.$2,
              icon: opt.$3,
              isSelected: currentSort == opt.$1,
              onTap: () => onSelected(opt.$1),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        decoration: isSelected
            ? const BoxDecoration(color: AppColors.hoverFill)
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
