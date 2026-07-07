import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
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
  int? get songId;
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
/// Brutalist design: 2px borders, sharp edges, progress bar at bottom.
///
/// Displays:
/// - Album art (44×44) via QueryArtworkWidget
/// - Song title + artist
/// - Play/pause & skip-next controls
/// - Thin progress bar at the bottom
///
/// Tapping the bar navigates to Now Playing.
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
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
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
                    _MiniArtwork(songId: state.songId),
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
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.border, width: 1.5),
                        ),
                        child: Icon(
                          state.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.xs),
                    GestureDetector(
                      onTap: onSkipNext,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.border, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.skip_next,
                          size: 20,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Progress bar ──────────────────────────────────────────────
            Container(
              height: 3,
              width: double.infinity,
              color: AppColors.outlineVariant,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({this.songId});

  final int? songId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: songId != null
          ? oaq.QueryArtworkWidget(
              id: songId!,
              type: oaq.ArtworkType.AUDIO,
              artworkWidth: 44,
              artworkHeight: 44,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.zero,
              keepOldArtwork: true,
              nullArtworkWidget: _placeholder(),
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Icon(
        Icons.music_note,
        size: 20,
        color: AppColors.outline,
      ),
    );
  }
}
