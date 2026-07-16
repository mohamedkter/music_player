import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../bloc/transfer_bloc.dart';

/// Shows live transfer progress for each song.
/// Used by both [SendScreen] and [ReceiveScreen].
class TransferProgressList extends StatelessWidget {
  const TransferProgressList({super.key, required this.state});

  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final isCompleted = state.status == TransferStatus.completed;
    final role = state.role ?? TransferRole.sender;

    return Column(
      children: [
        // ── Header
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
          ),
          child: Row(
            children: [
              // Status icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.gold,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.sync,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              AppSpacing.hGap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted
                          ? 'TRANSFER COMPLETE'
                          : role == TransferRole.sender
                              ? 'SENDING…'
                              : 'RECEIVING…',
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${state.completedCount}/${state.songProgresses.length} songs done'
                      '${state.failedCount > 0 ? " • ${state.failedCount} failed" : ""}',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Overall progress bar
        _OverallProgressBar(progress: state.overallProgress),

        // ── Song list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: state.songProgresses.length,
            itemBuilder: (_, i) {
              final item = state.songProgresses[i];
              return _SongProgressTile(item: item);
            },
          ),
        ),

        // ── Connected peer info
        if (state.connectedEndpointName != null || state.wifiIpAddress != null)
          _PeerBar(state: state),

        // ── Cancel button (only while transferring)
        if (!isCompleted)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GestureDetector(
              onTap: () {
                context
                    .read<TransferBloc>()
                    .add(const TransferSessionReset());
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                      color: AppColors.outlineVariant, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'CANCEL',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Overall bar ───────────────────────────────────────────────────────────────

class _OverallProgressBar extends StatelessWidget {
  const _OverallProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 6,
              color: AppColors.outlineVariant,
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 4),
          child: Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Per-song tile ─────────────────────────────────────────────────────────────

class _SongProgressTile extends StatelessWidget {
  const _SongProgressTile({required this.item});
  final SongTransferProgress item;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;

    if (item.failed) {
      statusColor = AppColors.error;
      statusIcon = Icons.close;
    } else if (item.done) {
      statusColor = AppColors.primary;
      statusIcon = Icons.check;
    } else if (item.progress > 0) {
      statusColor = AppColors.gold;
      statusIcon = Icons.sync;
    } else {
      statusColor = AppColors.outlineVariant;
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: AppSpacing.listItemPadding,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator square
              Container(
                width: 36,
                height: 36,
                color: statusColor.withValues(alpha: 0.12),
                child: Icon(statusIcon, size: 18, color: statusColor),
              ),
              AppSpacing.hGap(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.song.title,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.song.artist,
                      style: AppTextStyles.labelSm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Percentage or status label
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 2),
                color: statusColor,
                child: Text(
                  item.failed
                      ? 'FAILED'
                      : item.done
                          ? 'DONE'
                          : item.progress > 0
                              ? '${(item.progress * 100).toStringAsFixed(0)}%'
                              : 'QUEUED',
                  style: AppTextStyles.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          // Progress bar (only while in progress)
          if (!item.done && !item.failed && item.progress > 0) ...[
            AppSpacing.vGap(AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Stack(
                children: [
                  Container(height: 3, color: AppColors.outlineVariant),
                  FractionallySizedBox(
                    widthFactor: item.progress.clamp(0.0, 1.0),
                    child: Container(height: 3, color: AppColors.gold),
                  ),
                ],
              ),
            ),
          ],

          // Failure reason
          if (item.failed && item.failReason != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2),
              child: Text(
                item.failReason!,
                style: AppTextStyles.labelSm
                    .copyWith(color: AppColors.error, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Peer info bar ─────────────────────────────────────────────────────────────

class _PeerBar extends StatelessWidget {
  const _PeerBar({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          const Icon(Icons.devices, size: 16, color: AppColors.onSurfaceVariant),
          AppSpacing.hGap(AppSpacing.xs),
          if (state.connectedEndpointName != null)
            Text(
              state.connectedEndpointName!,
              style: AppTextStyles.labelSm,
            )
          else if (state.wifiIpAddress != null)
            Text(
              '${state.wifiIpAddress}:${state.wifiPort}',
              style: AppTextStyles.labelSm,
            ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
          ),
          AppSpacing.hGap(AppSpacing.xs),
          Text(
            'CONNECTED',
            style: AppTextStyles.labelSm.copyWith(
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
