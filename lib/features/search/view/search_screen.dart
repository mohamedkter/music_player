import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/inputs/app_search_bar.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../../player/bloc/player_bloc.dart';
import '../bloc/search_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: AppTextStyles.headlineMd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSearchBar(
              hintText: 'Songs, artists, albums...',
              autofocus: true,
              onChanged: (q) =>
                  context.read<SearchBloc>().add(SearchQueryChanged(q)),
              onClear: () =>
                  context.read<SearchBloc>().add(SearchCleared()),
            ),
          ),
          const Expanded(child: _Results()),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) => switch (state) {
        SearchIdle() => const AppEmptyState(
            icon: Icons.search,
            title: 'Search your library',
            message: 'Find songs, artists, albums and playlists.',
          ),
        SearchLoading() => const AppLoadingWidget(),
        SearchError(:final message) => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Search failed',
            message: message,
          ),
        SearchResults() => _ResultsList(state: state),
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.state});

  final SearchResults state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off,
        title: 'No results for "${state.query}"',
        message: 'Try a different search term.',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // ── Songs ──────────────────────────────────────────────────────────
        if (state.songs.isNotEmpty) ...[
          _SectionLabel(
            label: 'Songs',
            count: state.songs.length,
            onSeeAll: () {
              // Navigate to CategorySongsScreen with all matching songs
              AppRouter.pushCategorySongs(
                context,
                title: 'Songs — "${state.query}"',
                songs: state.songs,
              );
            },
          ),
          ...state.songs.map(
            (s) => BlocBuilder<PlayerBloc, PlayerState>(
              buildWhen: (prev, next) =>
                  prev.currentSong?.id != next.currentSong?.id ||
                  prev.isPlaying != next.isPlaying,
              builder: (context, playerState) {
                final isPlaying = playerState.isPlaying &&
                    playerState.currentSong?.id == s.id;
                return SongListItem(
                  songId: s.id,
                  title: s.title,
                  artist: s.artist,
                  durationMs: s.duration,
                  coverPath: s.coverPath,
                  isPlaying: isPlaying,
                  isFavorite: s.isFavorite,
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlayerSongRequested(song: s, queue: state.songs.cast()),
                    );
                  },
                );
              },
            ),
          ),
        ],

        // ── Artists ────────────────────────────────────────────────────────
        if (state.artists.isNotEmpty) ...[
          _SectionLabel(
            label: 'Artists',
            count: state.artists.length,
            onSeeAll: () {},  // Artist list screen — future feature
          ),
          ...state.artists.map(
            (a) => ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.person, color: AppColors.outline),
              ),
              title: Text(a.name, style: AppTextStyles.bodyMd),
              subtitle: Text(
                '${a.numberOfTracks} songs',
                style: AppTextStyles.labelSm,
              ),
              onTap: () {
                // Show all songs by this artist from the current search results
                final artistSongs = state.songs
                    .where((s) => s.artist == a.name)
                    .toList();
                AppRouter.pushCategorySongs(
                  context,
                  title: a.name,
                  songs: artistSongs,
                );
              },
            ),
          ),
        ],

        // ── Albums ─────────────────────────────────────────────────────────
        if (state.albums.isNotEmpty) ...[
          _SectionLabel(
            label: 'Albums',
            count: state.albums.length,
            onSeeAll: () => AppRouter.pushAlbums(context),
          ),
          ...state.albums.map(
            (a) => ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.album, color: AppColors.outline),
              ),
              title: Text(a.title, style: AppTextStyles.bodyMd),
              subtitle: Text(
                '${a.artist} · ${a.numberOfSongs} songs',
                style: AppTextStyles.labelSm,
              ),
              onTap: () => AppRouter.pushAlbumDetail(context, album: a),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.count,
    required this.onSeeAll,
  });

  final String label;
  final int count;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.headlineSm),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all ($count)',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
