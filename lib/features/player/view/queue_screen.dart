import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/list_items/song_list_item.dart';
import '../bloc/player_bloc.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Queue (${state.queue.length})',
                style: AppTextStyles.headlineSm),
            actions: [
              if (state.queue.length > 1)
                TextButton(
                  onPressed: () => _confirmClear(context),
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          body: state.queue.isEmpty
              ? const AppEmptyState(
                  icon: Icons.queue_music_outlined,
                  title: 'Queue is empty',
                  message: 'Play a song to start building your queue.',
                )
              : _QueueList(state: state),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        title: const Text('Clear Queue'),
        content: const Text('This will clear all songs from the queue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PlayerBloc>().add(PlayerQueueCleared());
            },
            child: Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: state.queue.length,
      onReorder: (oldIdx, newIdx) {
        if (newIdx > oldIdx) newIdx--;
        context.read<PlayerBloc>().add(
              PlayerQueueReordered(oldIndex: oldIdx, newIndex: newIdx),
            );
      },
      itemBuilder: (context, i) {
        final song = state.queue[i];
        final isCurrent = i == state.currentIndex;

        return Dismissible(
          key: ValueKey('${song.id}_$i'),
          direction: isCurrent
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => context
              .read<PlayerBloc>()
              .add(PlayerSongRemovedFromQueue(i)),
          child: SongListItem(
            key: ValueKey('item_${song.id}_$i'),
            songId: song.id,
            title: song.title,
            artist: song.artist,
            durationMs: song.duration,
            coverPath: song.coverPath,
            isPlaying: isCurrent,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(song.duration),
                  style: AppTextStyles.labelSm,
                ),
                if (!isCurrent) ...[
                  AppSpacing.hGap(AppSpacing.sm),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Icon(
                      Icons.drag_handle,
                      color: AppColors.outline,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
