import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../bloc/player_bloc.dart';

/// Bottom sheet that allows the user to select a sleep timer preset
/// or configure the timer to stop at the end of the current song.
/// Synchronized entirely with the central [PlayerBloc].
class SleepTimerBottomSheet extends StatelessWidget {
  const SleepTimerBottomSheet({super.key});

  void _startTimer(BuildContext context, int minutes) {
    final duration = Duration(minutes: minutes);
    context.read<PlayerBloc>().add(PlayerSleepTimerStarted(duration));
  }

  void _cancelTimer(BuildContext context) {
    context.read<PlayerBloc>().add(PlayerSleepTimerCancelled());
  }

  void _startTimerForEndOfSong(BuildContext context, PlayerState state) {
    final remaining = state.duration - state.position;
    if (remaining > Duration.zero) {
      context.read<PlayerBloc>().add(PlayerSleepTimerStarted(remaining));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final remaining = state.sleepTimerRemaining;

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
              if (remaining != null) ...[
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
                        'Stops in: ${DurationFormatter.format(remaining)}',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _cancelTimer(context),
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
                    onTap: () => _startTimer(context, mins),
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

              // Stop at end of song option
              if (state.hasSong)
                InkWell(
                  onTap: () => _startTimerForEndOfSong(context, state),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.music_off_outlined, size: 20),
                        AppSpacing.hGap(AppSpacing.sm),
                        Text(
                          'Stop at end of current song',
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              AppSpacing.vGap(AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}
