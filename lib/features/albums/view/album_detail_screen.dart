import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/album_model.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../../player/bloc/player_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    return _AlbumDetailLoader(album: album);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loader — fetches songs for this album
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumDetailLoader extends StatefulWidget {
  const _AlbumDetailLoader({required this.album});

  final AlbumModel album;

  @override
  State<_AlbumDetailLoader> createState() => _AlbumDetailLoaderState();
}

class _AlbumDetailLoaderState extends State<_AlbumDetailLoader> {
  late final Future<List<SongModel>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  Future<List<SongModel>> _loadSongs() async {
    final repo = sl<SongRepository>();
    final result = await repo.getSongsByAlbum(widget.album.id);
    return result.fold((_) => [], (songs) => songs);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: AppLoadingWidget(message: 'Loading album...'),
          );
        }
        return _AlbumDetailView(
          album: widget.album,
          songs: snapshot.data ?? [],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumDetailView extends StatelessWidget {
  const _AlbumDetailView({required this.album, required this.songs});

  final AlbumModel album;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _AlbumHeader(album: album, songs: songs),
          _AlbumActions(album: album, songs: songs),
          _AlbumSongsList(songs: songs),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — artwork + meta
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.album, required this.songs});

  final AlbumModel album;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    final firstSongId = songs.isNotEmpty ? songs.first.id : null;

    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // ── Blurred background ──────────────────────────────────────────
          SizedBox(
            height: 300,
            width: double.infinity,
            child: firstSongId != null
                ? oaq.QueryArtworkWidget(
                    id: firstSongId,
                    type: oaq.ArtworkType.AUDIO,
                    artworkFit: BoxFit.cover,
                    artworkBorder: BorderRadius.zero,
                    keepOldArtwork: true,
                    nullArtworkWidget: _PlaceholderBg(),
                    errorBuilder: (_, __, ___) => _PlaceholderBg(),
                  )
                : _PlaceholderBg(),
          ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(80),
                    Colors.black.withAlpha(200),
                  ],
                ),
              ),
            ),
          ),
          // ── Back button ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border.all(color: Colors.white38, width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // ── Album info ──────────────────────────────────────────────────
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title.toUpperCase(),
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  album.artist,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (album.year != null) album.year.toString(),
                    '${songs.length} TRACKS',
                  ].join(' · '),
                  style: AppTextStyles.labelSm.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.album, size: 80, color: AppColors.outlineVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Shuffle action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumActions extends StatelessWidget {
  const _AlbumActions({required this.album, required this.songs});

  final AlbumModel album;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // ── Play All ─────────────────────────────────────────────────
            Expanded(
              child: _ActionButton(
                icon: Icons.play_arrow,
                label: 'PLAY ALL',
                isPrimary: true,
                onTap: () => context.read<PlayerBloc>().add(
                      PlayerSongRequested(song: songs.first, queue: songs),
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // ── Shuffle ──────────────────────────────────────────────────
            Expanded(
              child: _ActionButton(
                icon: Icons.shuffle,
                label: 'SHUFFLE',
                isPrimary: false,
                onTap: () {
                  final shuffled = List<SongModel>.from(songs)..shuffle();
                  context.read<PlayerBloc>().add(
                        PlayerSongRequested(
                          song: shuffled.first,
                          queue: shuffled,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          boxShadow: isPrimary
              ? const [
                  BoxShadow(
                    color: AppColors.shadowPrimary,
                    offset: Offset(3, 3),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.shadowNeutral,
                    offset: Offset(3, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? AppColors.onPrimary : AppColors.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: isPrimary ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Songs list
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumSongsList extends StatelessWidget {
  const _AlbumSongsList({required this.songs});

  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.music_off_outlined,
          title: 'NO SONGS FOUND',
          message: 'No songs were found for this album.',
        ),
      );
    }

    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        return SliverList.builder(
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
              trackNumber: index + 1,
              isPlaying: isPlaying,
              isFavorite: song.isFavorite,
              onTap: () => context.read<PlayerBloc>().add(
                    PlayerSongRequested(song: song, queue: songs),
                  ),
            );
          },
        );
      },
    );
  }
}
