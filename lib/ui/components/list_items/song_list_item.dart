import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';

/// Standard song row used in Songs, Queue, Playlist detail, and folder views.
///
/// Supports:
/// - Artwork thumbnail
/// - Favorite & more-options actions
/// - Active / playing highlight
/// - Track number display (optional)
///
/// Usage:
/// ```dart
/// SongListItem(
///   title: song.title,
///   artist: song.artist,
///   durationMs: song.duration,
///   coverPath: song.coverPath,
///   isPlaying: currentId == song.id,
///   isFavorite: song.isFavorite,
///   onTap: () => bloc.add(PlaySong(song)),
///   onFavoriteTap: () => bloc.add(ToggleFavorite(song.id)),
///   onMoreTap: () => showSongOptions(song),
/// )
/// ```
class SongListItem extends StatelessWidget {
  const SongListItem({
    super.key,
    required this.title,
    required this.artist,
    required this.durationMs,
    this.album,
    this.coverPath,
    this.trackNumber,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onMoreTap,
    this.trailing,
  });

  final String title;
  final String artist;
  final int durationMs;
  final String? album;
  final String? coverPath;
  final int? trackNumber;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onMoreTap;

  /// Override the default [favorite + more] trailing with a custom widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textColor = isPlaying ? AppColors.primary : AppColors.onSurface;

    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Container(
        padding: AppSpacing.listItemPadding,
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.hoverFill
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.outlineVariant,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // ── Artwork / Track Number ────────────────────────────────────
            _buildLeading(context),
            AppSpacing.hGap(AppSpacing.md),

            // ── Title + Artist ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: textColor,
                      fontWeight:
                          isPlaying ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vGap(2),
                  Text(
                    album != null ? '$artist · $album' : artist,
                    style: AppTextStyles.labelSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Duration + Actions ────────────────────────────────────────
            if (trailing != null)
              trailing!
            else
              _buildTrailing(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (trackNumber != null) {
      return SizedBox(
        width: 40,
        child: Center(
          child: isPlaying
              ? const _PlayingIndicator()
              : Text(
                  trackNumber.toString(),
                  style: AppTextStyles.labelMd,
                ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: _buildArtwork(),
    );
  }

  Widget _buildArtwork() {
    if (coverPath != null && coverPath!.isNotEmpty) {
      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ArtworkPlaceholder(),
      );
    }
    return const _ArtworkPlaceholder();
  }

  Widget _buildTrailing(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DurationFormatter.fromMilliseconds(durationMs),
          style: AppTextStyles.labelSm,
        ),
        if (onFavoriteTap != null) ...[
          AppSpacing.hGap(AppSpacing.xs),
          GestureDetector(
            onTap: onFavoriteTap,
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isFavorite ? AppColors.error : AppColors.outline,
            ),
          ),
        ],
        if (onMoreTap != null) ...[
          AppSpacing.hGap(AppSpacing.xs),
          GestureDetector(
            onTap: onMoreTap,
            child: Icon(
              Icons.more_vert,
              size: 18,
              color: AppColors.outline,
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated playing indicator (three bouncing bars).
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  static const int _barCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true);
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_barCount, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            width: 3,
            height: 8 + _controllers[i].value * 10,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: AppColors.primary,
          ),
        );
      }),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.music_note, size: 20, color: AppColors.outline),
      ),
    );
  }
}
