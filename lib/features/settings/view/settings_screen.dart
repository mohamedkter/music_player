import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<SettingsBloc>()..add(SettingsLoadRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Brutalist AppBar ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SETTINGS',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            border: Border.all(color: AppColors.border, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowNeutral,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: AppColors.onSurface,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Section: APPEARANCE ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    title: 'APPEARANCE',
                    children: [
                      _SettingTile(
                        label: 'THEME MODE',
                        subtitle: _themeName(state.themeMode).toUpperCase(),
                        trailing: _ThemePicker(current: state.themeMode),
                      ),
                      _SettingTile(
                        label: 'DYNAMIC COLOR',
                        subtitle: 'EXTRACT COLOR FROM ALBUM ARTWORK',
                        trailing: _BrutalistSwitch(
                          value: state.dynamicColorEnabled,
                          onChanged: (_) => context
                              .read<SettingsBloc>()
                              .add(SettingsDynamicColorToggled()),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Section: LIBRARY ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    title: 'LIBRARY MANAGEMENT',
                    children: [
                      _SettingTile(
                        label: 'IGNORE SHORT AUDIO',
                        subtitle: 'EXCLUDE FILES UNDER ${state.minAudioDuration} SECONDS',
                        trailing: _BrutalistSwitch(
                          value: state.ignoreShortAudio,
                          onChanged: (_) => context
                              .read<SettingsBloc>()
                              .add(SettingsIgnoreShortAudioToggled()),
                        ),
                      ),
                      if (state.ignoreShortAudio)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: _DurationSlider(current: state.minAudioDuration),
                        ),
                      _SettingTile(
                        label: 'SCAN MUSIC LIBRARY',
                        subtitle: state.lastScanCount != null
                            ? 'LAST SCAN: ${state.lastScanCount} SONGS FOUND'
                            : 'TAP TO SCAN DEVICE STORAGE',
                        trailing: state.isScanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'SCAN',
                                  style: AppTextStyles.labelSm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                        onTap: state.isScanning
                            ? null
                            : () => context
                                  .read<SettingsBloc>()
                                  .add(SettingsScanRequested()),
                      ),
                    ],
                  ),
                ),

                // ── Section: AUDIO ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    title: 'AUDIO SETTINGS',
                    children: [
                      _SettingTile(
                        label: 'EQUALIZER',
                        subtitle: 'ADJUST SOUND FREQUENCIES',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurface,
                        ),
                        onTap: () {
                          // Placeholder for future EQ screen navigation
                        },
                      ),
                      _SettingTile(
                        label: 'PLAYBACK SPEED',
                        subtitle: 'DEFAULT SPEED: 1.0X',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurface,
                        ),
                        onTap: () {
                          // Placeholder
                        },
                      ),
                    ],
                  ),
                ),

                // ── Section: INFO ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionContainer(
                    title: 'APPLICATION INFO',
                    children: [
                      _SettingTile(
                        label: AppConstants.appName.toUpperCase(),
                        subtitle: 'VERSION ${AppConstants.appVersion}',
                        leading: const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      const _SettingTile(
                        label: 'POWERED BY FLUTTER',
                        subtitle: 'OPEN SOURCE LOCAL MUSIC ENGINE',
                        leading: Icon(
                          Icons.code,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _themeName(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Brutalist Section Container panel
// ─────────────────────────────────────────────────────────────────────────────

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowNeutral,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.border,
            ),
            child: Text(
              title,
              style: AppTextStyles.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setting Tile Row
// ─────────────────────────────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.label,
    required this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String label;
  final String subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              AppSpacing.hGap(AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing as Widget,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme selection pill buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.current});

  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ThemeMode.values.map((mode) {
        final isSelected = mode == current;
        return GestureDetector(
          onTap: () => context
              .read<SettingsBloc>()
              .add(SettingsThemeChanged(mode)),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Text(
              _label(mode),
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(ThemeMode m) => switch (m) {
        ThemeMode.light => 'LIGHT',
        ThemeMode.dark => 'DARK',
        ThemeMode.system => 'AUTO',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Brutalist Switch
// ─────────────────────────────────────────────────────────────────────────────

class _BrutalistSwitch extends StatelessWidget {
  const _BrutalistSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.outlineVariant,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration Slider styled brutalist
// ─────────────────────────────────────────────────────────────────────────────

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MIN TRACK DURATION',
              style: AppTextStyles.labelSm.copyWith(fontSize: 10),
            ),
            Text(
              '${current}S',
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.outlineVariant,
            trackHeight: 4,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 2,
            ),
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: current.toDouble(),
            min: 10,
            max: 120,
            divisions: 22,
            onChanged: (v) => context
                .read<SettingsBloc>()
                .add(SettingsMinDurationChanged(v.round())),
          ),
        ),
      ],
    );
  }
}
