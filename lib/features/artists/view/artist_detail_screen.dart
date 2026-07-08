import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/artist_model.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../../player/bloc/player_bloc.dart';

class ArtistDetailScreen extends StatelessWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    return _ArtistDetailLoader(artist: artist);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loader
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistDetailLoader extends StatefulWidget {
  const _ArtistDetailLoader({required this.artist});

  final ArtistModel artist;

  @override
  State<_ArtistDetailLoader> createState() => _ArtistDetailLoaderState();
}

class _ArtistDetailLoaderState extends State<_ArtistDetailLoader> {
  late final Future<List<SongModel>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _loadSongs();
  }

  Future<List<SongModel>> _loadSongs() async {
    final repo = sl<SongRepository>();
    final result = await repo.getSongsByArtist(widget.artist.id);
    return result.fold((_) => [], (songs) => songs);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: AppLoadingWidget(message: 'Loading artist...'),
          );
        }
        return _ArtistDetailView(
          artist: widget.artist,
          songs: snapshot.data ?? [],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistDetailView extends StatelessWidget {
  const _ArtistDetailView({required this.artist, required this.songs});

  final ArtistModel artist;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _ArtistHeader(artist: artist, songs: songs),
          _ArtistActions(artist: artist, songs: songs),
          _ArtistSongsList(songs: songs),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistHeader extends StatelessWidget {
  const _ArtistHeader({required this.artist, required this.songs});

  final ArtistModel artist;
  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Background artwork
          SizedBox(
            height: 260,
            width: double.infinity,
            child: oaq.QueryArtworkWidget(
              id: artist.id,
              type: oaq.ArtworkType.ARTIST,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.zero,
              keepOldArtwork: true,
              nullArtworkWidget: _ArtistPlaceholderBg(),
              errorBuilder: (_, __, ___) => _ArtistPlaceholderBg(),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(60),
                    Colors.black.withAlpha(210),
                  ],
                ),
              ),
            ),
          ),
          // Back button
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
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
              ),
            ),
          ),
          // Artist info
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name.toUpperCase(),
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '${songs.length} TRACKS',
                    if (artist.numberOfAlbums > 0)
                      '${artist.numberOfAlbums} ALBUMS',
                  ].join(' · '),
                  style: AppTextStyles.labelSm.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistPlaceholderBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.person, size: 80, color: AppColors.outlineVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Shuffle
// ─────────────────────────────────────────────────────────────────────────────

class _ArtistActions extends StatelessWidget {
  const _ArtistActions({required this.artist, required this.songs});

  final ArtistModel artist;
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
            Expanded(
              child: _ActionBtn(
                icon: Icons.play_arrow,
                label: 'PLAY ALL',
                isPrimary: true,
                onTap: () => context.read<PlayerBloc>().add(
                      PlayerSongRequested(song: songs.first, queue: songs),
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionBtn(
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
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
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppColors.shadowPrimary
                  : AppColors.shadowNeutral,
              offset: const Offset(3, 3),
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

class _ArtistSongsList extends StatelessWidget {
  const _ArtistSongsList({required this.songs});

  final List<SongModel> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.music_off_outlined,
          title: 'NO SONGS FOUND',
          message: 'No songs found for this artist.',
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
