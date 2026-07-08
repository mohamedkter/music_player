import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../ui/components/feedback/app_empty_state.dart';
import '../../../ui/components/feedback/app_error_widget.dart';
import '../../../ui/components/feedback/app_loading.dart';
import '../bloc/folders_bloc.dart';

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<FoldersBloc>()..add(FoldersLoadRequested()),
      child: const _FoldersView(),
    );
  }
}

class _FoldersView extends StatelessWidget {
  const _FoldersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      child: BlocBuilder<FoldersBloc, FoldersState>(
        builder: (context, state) {
          final count = state is FoldersLoaded ? state.folders.length : 0;
          return Row(
            children: [
              Text(
                'FOLDERS',
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.gold,
                  child: Text(
                    '$count',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.border,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoldersBloc, FoldersState>(
      builder: (context, state) => switch (state) {
        FoldersInitial() => const SizedBox.shrink(),
        FoldersLoading() =>
          const AppLoadingWidget(message: 'Scanning folders...'),
        FoldersError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                context.read<FoldersBloc>().add(FoldersLoadRequested()),
          ),
        FoldersLoaded(:final folders) => folders.isEmpty
            ? const AppEmptyState(
                icon: Icons.folder_off_outlined,
                title: 'No Folders Found',
                message: 'No audio files were found on your device.',
              )
            : _FoldersList(folders: folders),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Folders list
// ─────────────────────────────────────────────────────────────────────────────

class _FoldersList extends StatelessWidget {
  const _FoldersList({required this.folders});

  final List<FolderEntry> folders;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _FolderTile(folder: folder);
      },
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder});

  final FolderEntry folder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AppRouter.pushCategorySongs(
        context,
        title: folder.name,
        songs: folder.songs,
      ),
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            // Folder icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                border: Border.all(color: AppColors.border, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowNeutral,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name.toUpperCase(),
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    folder.path,
                    style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${folder.songCount} TRACKS',
                    style: AppTextStyles.labelSm,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
