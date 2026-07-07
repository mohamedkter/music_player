import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bottom navigation item model.
class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Brutalist bottom navigation bar.
///
/// Sharp edges, 2px top border, monospaced uppercase labels.
/// Selected item uses gold/yellow highlight background; unselected uses neutral.
///
/// Usage:
/// ```dart
/// AppBottomNav(
///   currentIndex: _currentIndex,
///   onTap: (i) => setState(() => _currentIndex = i),
///   items: AppNavItems.all,
/// )
/// ```
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: _NavTab(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          border: Border(
            left: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              item.label.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default navigation items for the app.
abstract final class AppNavItems {
  static const List<AppNavItem> all = [
    AppNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    AppNavItem(
      icon: Icons.queue_music_outlined,
      activeIcon: Icons.queue_music,
      label: 'Queue',
    ),
    AppNavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music,
      label: 'Library',
    ),
    AppNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];
}
