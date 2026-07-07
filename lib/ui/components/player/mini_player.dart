import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';

/// Contract for the player state that MiniPlayer requires.
/// Any BLoC state used here must implement this interface.
abstract interface class MiniPlayerState {
  String get songTitle;
  String get artistName;
  String? get coverPath;
  bool get isPlaying;
  Duration get position;
  Duration get duration;
}

/// Contract for the player BLoC events.
abstract interface class MiniPlayerEventSink {
  void togglePlayPause();
  void skipToNext();
}

/// Persistent mini player bar shown above the Bottom Navigation.
///
/// Displays:
/// - Album art (48×48)
/// - Song title + artist (with marquee on overflow)
/// - Play/pause & skip-next controls
/// - Thin progress bar at the bottom
///
/// Tapping the bar navigates to Now Playing.
///
/// This widget is generic over the BLoC type to remain reusable
/// without tight coupling to a specific implementation.
///
/// Usage in shell scaffold:
/// ```dart
/// MiniPlayer<PlayerBloc, PlayerBlocState>(
///   stateBuilder: (s) => s,           // adapt state → MiniPlayerState
///   onPlayPause: () => context.read<PlayerBloc>().add(TogglePlayPause()),
///   onSkipNext: () => context.read<PlayerBloc>().add(SkipToNext()),
///   onTap: () => Navigator.pushNamed(context, '/now-playing'),
/// )
/// ```
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onTap,
  });

  final MiniPlayerState state;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 2),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // ── Artwork ───────────────────────────────────────────
                    _MiniArtwork(coverPath: state.coverPath),
                    AppSpacing.hGap(AppSpacing.sm),

                    // ── Title / Artist ────────────────────────────────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.songTitle,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            state.artistName,
                            style: AppTextStyles.labelSm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // ── Time ──────────────────────────────────────────────
                    Text(
                      DurationFormatter.format(state.position),
                      style: AppTextStyles.labelSm,
                    ),
                    AppSpacing.hGap(AppSpacing.sm),

                    // ── Controls ──────────────────────────────────────────
                    GestureDetector(
                      onTap: onPlayPause,
                      child: Icon(
                        state.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.xs),
                    GestureDetector(
                      onTap: onSkipNext,
                      child: const Icon(
                        Icons.skip_next,
                        size: 28,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Progress bar ──────────────────────────────────────────────
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.outlineVariant,
              color: AppColors.primary,
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({this.coverPath});

  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: coverPath != null && coverPath!.isNotEmpty
          ? Image.file(File(coverPath!), fit: BoxFit.cover)
          : Container(
              color: AppColors.surfaceContainerHigh,
              child: const Icon(
                Icons.music_note,
                size: 20,
                color: AppColors.outline,
              ),
            ),
    );
  }
}
