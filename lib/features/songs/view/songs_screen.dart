import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_error_widget.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../../../ui/components/inputs/app_search_bar.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../bloc/songs_bloc.dart';
import 'widgets/sort_bottom_sheet.dart';

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ctx.read<SongsBloc>()..add(SongsLoadRequested()),
      child: const _SongsView(),
    );
  }
}

class _SongsView extends StatelessWidget {
  const _SongsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            const Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Songs', style: AppTextStyles.headlineMd),
              BlocBuilder<SongsBloc, SongsState>(
                builder: (ctx, state) {
                  return GestureDetector(
                    onTap: () => _showSortSheet(ctx),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sort,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppSpacing.hGap(AppSpacing.xs),
                        Text('Sort', style: AppTextStyles.labelMd),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpacing.vGap(AppSpacing.sm),
          AppSearchBar(
            hintText: 'Search songs...',
            onChanged: (q) =>
                context.read<SongsBloc>().add(SongsSearchChanged(q)),
            onClear: () =>
                context.read<SongsBloc>().add(SongsSearchCleared()),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final bloc = context.read<SongsBloc>();
    final current = bloc.state is SongsLoaded
        ? (bloc.state as SongsLoaded).sort
        : SongSortOption.titleAsc;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SortBottomSheet(
        currentSort: current,
        onSelected: (opt) {
          bloc.add(SongsSortChanged(opt));
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, state) {
        return switch (state) {
          SongsInitial() => const SizedBox.shrink(),
          SongsLoading() => const AppLoadingWidget(message: 'Loading songs...'),
          SongsError(:final message) => AppErrorWidget(
              message: message,
              onRetry: () =>
                  context.read<SongsBloc>().add(SongsLoadRequested()),
            ),
          SongsLoaded(:final songs, :final allSongs, :final searchQuery) =>
            songs.isEmpty
                ? AppEmptyState(
                    icon: searchQuery.isNotEmpty
                        ? Icons.search_off
                        : Icons.library_music_outlined,
                    title: searchQuery.isNotEmpty
                        ? 'No results for "$searchQuery"'
                        : 'No Songs Found',
                    message: searchQuery.isNotEmpty
                        ? null
                        : 'Tap Scan to load your music library.',
                  )
                : _SongsList(songs: songs, totalCount: allSongs.length),
        };
      },
    );
  }
}

class _SongsList extends StatelessWidget {
  const _SongsList({required this.songs, required this.totalCount});

  final List<dynamic> songs;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              '${songs.length} of $totalCount',
              style: AppTextStyles.labelMd,
            ),
          ),
        ),
        SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongListItem(
              title: song.title,
              artist: song.artist,
              album: song.album,
              durationMs: song.duration,
              coverPath: song.coverPath,
              isFavorite: song.isFavorite,
              onTap: () {
                // TODO: connect to PlayerBloc.add(PlaySong(song, queue: songs))
              },
              onFavoriteTap: () => context
                  .read<SongsBloc>()
                  .add(SongFavoriteToggled(song.id)),
              onMoreTap: () => _showSongOptions(context, song),
            );
          },
        ),
        // Bottom padding for Mini Player
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _showSongOptions(BuildContext context, dynamic song) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SongOptionsSheet(song: song),
    );
  }
}

class _SongOptionsSheet extends StatelessWidget {
  const _SongOptionsSheet({required this.song});

  final dynamic song;

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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionTile(icon: Icons.play_arrow, label: 'Play', onTap: () {}),
          _OptionTile(icon: Icons.skip_next, label: 'Play Next', onTap: () {}),
          _OptionTile(icon: Icons.playlist_add, label: 'Add to Playlist', onTap: () {}),
          _OptionTile(
            icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: song.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onTap: () {
              context.read<SongsBloc>().add(SongFavoriteToggled(song.id));
              Navigator.pop(context);
            },
          ),
          _OptionTile(icon: Icons.album, label: 'Go to Album', onTap: () {}),
          _OptionTile(icon: Icons.person, label: 'Go to Artist', onTap: () {}),
          _OptionTile(icon: Icons.folder_open, label: 'Show in Folder', onTap: () {}),
          _OptionTile(icon: Icons.info_outline, label: 'Song Info', onTap: () {}),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
            AppSpacing.hGap(AppSpacing.md),
            Text(label, style: AppTextStyles.bodyMd),
          ],
        ),
      ),
    );
  }
}
