import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../player/bloc/player_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Generic Category Songs Screen
// ─────────────────────────────────────────────────────────────────────────────

class CategorySongsScreen extends StatelessWidget {
  const CategorySongsScreen({
    super.key,
    required this.title,
    required this.songs,
  });

  final String title;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppTextStyles.headlineSm.copyWith(
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2, color: AppColors.border),

            // Songs List
            Expanded(
              child: songs.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.music_off_outlined,
                      title: 'NO SONGS IN THIS LIST',
                      message: 'Scan your device to load local audio files.',
                    )
                  : BlocBuilder<PlayerBloc, PlayerState>(
                      builder: (context, playerState) {
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            final isPlaying = playerState.isPlaying &&
                                playerState.currentSong?.id == song.id;

                            return SongListItem(
                              title: song.title,
                              artist: song.artist,
                              durationMs: song.duration,
                              songId: song.id,
                              coverPath: song.coverPath,
                              isPlaying: isPlaying,
                              onTap: () {
                                context.read<PlayerBloc>().add(
                                      PlayerSongRequested(
                                        song: song,
                                        queue: songs,
                                      ),
                                    );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlists List Screen
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistsListScreen extends StatelessWidget {
  const PlaylistsListScreen({
    super.key,
    required this.playlists,
  });

  final List<PlaylistModel> playlists;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'PLAYLISTS',
                      style: AppTextStyles.headlineSm.copyWith(
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2, color: AppColors.border),

            // Playlists List
            Expanded(
              child: playlists.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.playlist_remove_outlined,
                      title: 'NO PLAYLISTS FOUND',
                      message: 'Create a playlist from the options in Now Playing.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final pl = playlists[index];
                        final firstSongId =
                            pl.songs.isNotEmpty ? pl.songs.first.id : null;

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => CategorySongsScreen(
                                  title: pl.name,
                                  songs: pl.songs,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.outlineVariant,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 2,
                                    ),
                                    color: AppColors.surfaceContainerHigh,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: firstSongId != null
                                      ? oaq.QueryArtworkWidget(
                                          id: firstSongId,
                                          type: oaq.ArtworkType.AUDIO,
                                          artworkWidth: 50,
                                          artworkHeight: 50,
                                          artworkFit: BoxFit.cover,
                                          artworkBorder: BorderRadius.zero,
                                          keepOldArtwork: true,
                                          nullArtworkWidget: const Icon(
                                            Icons.playlist_play,
                                            color: AppColors.outline,
                                            size: 24,
                                          ),
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.playlist_play,
                                            color: AppColors.outline,
                                            size: 24,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.playlist_play,
                                          color: AppColors.outline,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pl.name.toUpperCase(),
                                        style: AppTextStyles.bodyMd.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pl.songCount} TRACKS',
                                        style: AppTextStyles.labelSm,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.outline,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
