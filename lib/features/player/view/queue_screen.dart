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
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                _Header(state: state),
                Expanded(
                  child: state.queue.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.queue_music_outlined,
                          title: 'QUEUE IS EMPTY',
                          message: 'Play a song to start building your queue.',
                        )
                      : _QueueList(state: state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final PlayerState state;

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const Border(
          top: BorderSide(color: AppColors.border, width: 3),
          bottom: BorderSide(color: AppColors.border, width: 3),
          left: BorderSide(color: AppColors.border, width: 3),
          right: BorderSide(color: AppColors.border, width: 3),
        ),
        title: Text(
          'CLEAR QUEUE',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        content: const Text(
          'This will clear all songs from the queue.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          // Cancel Button (Brutalist White)
          GestureDetector(
            onTap: () => Navigator.pop(dialogCtx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                color: Colors.white,
              ),
              child: Text(
                'CANCEL',
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.border,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear Button (Brutalist Red/Error)
          GestureDetector(
            onTap: () {
              Navigator.pop(dialogCtx);
              context.read<PlayerBloc>().add(PlayerQueueCleared());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                color: AppColors.error,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowNeutral,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                'CLEAR',
                style: AppTextStyles.labelMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canClear = state.queue.length > 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      child: Row(
        children: [
        
          // Title
          Expanded(
            child: Text(
              'QUEUE',
              style: AppTextStyles.headlineMd.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Clear all button (Brutalist Gold)
          if (canClear)
            GestureDetector(
              onTap: () => _confirmClear(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowNeutral,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  'CLEAR ALL',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.border,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
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
                if (!isCurrent)
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
