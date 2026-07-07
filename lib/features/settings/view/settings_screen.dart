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
    return BlocProvider(
      create: (ctx) => ctx.read<SettingsBloc>()..add(SettingsLoadRequested()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headlineMd),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            _AppearanceSection(state: state),
            _Divider(),
            _LibrarySection(state: state),
            _Divider(),
            _AudioSection(),
            _Divider(),
            _AboutSection(),
          ],
        ),
      ),
    );
  }
}

// ── Appearance ────────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '🎨 Appearance',
      children: [
        _SettingTile(
          label: 'Theme',
          subtitle: _themeName(state.themeMode),
          trailing: _ThemePicker(current: state.themeMode),
        ),
        _SettingTile(
          label: 'Dynamic Color',
          subtitle: 'Extract color from album artwork',
          trailing: _StudioSwitch(
            value: state.dynamicColorEnabled,
            onChanged: (_) => context
                .read<SettingsBloc>()
                .add(SettingsDynamicColorToggled()),
          ),
        ),
      ],
    );
  }

  String _themeName(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };
}

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
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            margin: const EdgeInsets.only(left: AppSpacing.xs),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.outline,
                width: 2,
              ),
            ),
            child: Text(
              _label(mode),
              style: AppTextStyles.labelSm.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'Auto',
      };
}

// ── Library ───────────────────────────────────────────────────────────────────

class _LibrarySection extends StatelessWidget {
  const _LibrarySection({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '📚 Library',
      children: [
        _SettingTile(
          label: 'Ignore Short Audio',
          subtitle: 'Files under ${state.minAudioDuration}s are excluded',
          trailing: _StudioSwitch(
            value: state.ignoreShortAudio,
            onChanged: (_) => context
                .read<SettingsBloc>()
                .add(SettingsIgnoreShortAudioToggled()),
          ),
        ),
        if (state.ignoreShortAudio)
          _DurationSlider(current: state.minAudioDuration),
        _SettingTile(
          label: 'Scan Music Library',
          subtitle: state.lastScanCount != null
              ? 'Last scan: ${state.lastScanCount} songs found'
              : 'Tap to scan your device',
          trailing: state.isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : null,
          onTap: state.isScanning
              ? null
              : () => context
                    .read<SettingsBloc>()
                    .add(SettingsScanRequested()),
        ),
      ],
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minimum duration: ${current}s',
            style: AppTextStyles.labelMd,
          ),
          Slider(
            value: current.toDouble(),
            min: 10,
            max: 120,
            divisions: 22,
            label: '${current}s',
            onChanged: (v) => context
                .read<SettingsBloc>()
                .add(SettingsMinDurationChanged(v.round())),
          ),
        ],
      ),
    );
  }
}

// ── Audio ─────────────────────────────────────────────────────────────────────

class _AudioSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '🎵 Audio',
      children: [
        _SettingTile(
          label: 'Equalizer',
          subtitle: 'Adjust sound frequencies',
          trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: () {}, // TODO: open equalizer
        ),
        _SettingTile(
          label: 'Playback Speed',
          subtitle: 'Default: 1.0x',
          trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: () {},
        ),
      ],
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'ℹ About',
      children: [
        _SettingTile(
          label: AppConstants.appName,
          subtitle: 'Version ${AppConstants.appVersion}',
          leading: const Icon(Icons.music_note, color: AppColors.primary),
        ),
        _SettingTile(
          label: 'Built with Flutter 💙',
          subtitle: 'Open source music player',
        ),
      ],
    );
  }
}

// ── Shared Components ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
          ),
          child: Text(title, style: AppTextStyles.headlineSm),
        ),
        ...children,
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.label,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String label;
  final String? subtitle;
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
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
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
                  Text(label, style: AppTextStyles.bodyMd),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.labelSm),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _StudioSwitch extends StatelessWidget {
  const _StudioSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.outline,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.all(2),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 0, thickness: 2);
}
