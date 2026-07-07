import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../bloc/player_bloc.dart';

class SleepTimerBottomSheet extends StatefulWidget {
  const SleepTimerBottomSheet({super.key});

  @override
  State<SleepTimerBottomSheet> createState() => _SleepTimerBottomSheetState();
}

class _SleepTimerBottomSheetState extends State<SleepTimerBottomSheet> {
  Timer? _countdownTimer;
  Duration? _remaining;
  bool _stopAtEndOfSong = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    _countdownTimer?.cancel();
    final duration = Duration(minutes: minutes);
    setState(() => _remaining = duration);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining == null || _remaining! <= Duration.zero) {
        _countdownTimer?.cancel();
        // Stop playback
        context.read<PlayerBloc>().add(PlayerTogglePlayPause());
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() => _remaining = _remaining! - const Duration(seconds: 1));
    });
  }

  void _cancel() {
    _countdownTimer?.cancel();
    setState(() => _remaining = null);
  }

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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              AppSpacing.hGap(AppSpacing.sm),
              Text('Sleep Timer', style: AppTextStyles.headlineSm),
            ],
          ),
          AppSpacing.vGap(AppSpacing.md),

          // Active timer display
          if (_remaining != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.hoverFill,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stops in: ${DurationFormatter.format(_remaining!)}',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancel,
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGap(AppSpacing.md),
          ],

          // Preset buttons
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AppConstants.sleepTimerPresets.map((mins) {
              return GestureDetector(
                onTap: () => _startTimer(mins),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline, width: 2),
                  ),
                  child: Text(
                    DurationFormatter.toLabel(mins * 60),
                    style: AppTextStyles.labelMd,
                  ),
                ),
              );
            }).toList(),
          ),

          AppSpacing.vGap(AppSpacing.md),

          // Stop at end of song toggle
          InkWell(
            onTap: () =>
                setState(() => _stopAtEndOfSong = !_stopAtEndOfSong),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _stopAtEndOfSong
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: _stopAtEndOfSong
                          ? AppColors.primary
                          : AppColors.outline,
                      width: 2,
                    ),
                  ),
                  child: _stopAtEndOfSong
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                AppSpacing.hGap(AppSpacing.sm),
                Text(
                  'Stop at end of current song',
                  style: AppTextStyles.bodyMd,
                ),
              ],
            ),
          ),
          AppSpacing.vGap(AppSpacing.md),
        ],
      ),
    );
  }
}
