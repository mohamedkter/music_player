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

/// Studio-styled bottom navigation bar.
///
/// Sharp edges, 2px top border, monospaced labels.
/// Selected item uses primary color; unselected uses onSurfaceVariant.
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
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
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
    final color =
        isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? item.activeIcon : item.icon,
            size: 22,
            color: color,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: AppTextStyles.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Default navigation items for the app.
abstract final class AppNavItems {
  static const List<AppNavItem> all = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    AppNavItem(
      icon: Icons.music_note_outlined,
      activeIcon: Icons.music_note,
      label: 'Songs',
    ),
    AppNavItem(
      icon: Icons.album_outlined,
      activeIcon: Icons.album,
      label: 'Albums',
    ),
    AppNavItem(
      icon: Icons.queue_music_outlined,
      activeIcon: Icons.queue_music,
      label: 'Playlists',
    ),
    AppNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];
}
