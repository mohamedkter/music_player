import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../bloc/transfer_bloc.dart';
import 'widgets/transfer_progress_list.dart';
import 'widgets/transfer_shared_widgets.dart';

/// Sender screen — select songs → start sharing → monitor progress.
class SendScreen extends StatelessWidget {
  const SendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state.status == TransferStatus.completed) {
          _showCompletedDialog(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: switch (state.status) {
              TransferStatus.selectingSongs ||
              TransferStatus.idle ||
              TransferStatus.selectingMethod =>
                _SongPickerView(state: state),
              TransferStatus.advertising => _AdvertisingView(state: state),
              TransferStatus.serverRunning => _QrCodeView(state: state),
              TransferStatus.connectionPending =>
                _ConnectionRequestView(state: state),
              TransferStatus.connecting => _ConnectingView(state: state),
              TransferStatus.transferring ||
              TransferStatus.completed =>
                TransferProgressList(state: state),
              TransferStatus.failed => _FailedView(state: state),
              _ => _SongPickerView(state: state),
            },
          ),
        );
      },
    );
  }

  void _showCompletedDialog(BuildContext context, TransferState state) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        title: Text(
          'TRANSFER COMPLETE',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${state.completedCount} songs sent successfully.'
          '${state.failedCount > 0 ? "\n${state.failedCount} failed." : ""}',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TransferBloc>().add(const TransferSessionReset());
              Navigator.of(context).pop();
            },
            child: Text(
              'DONE',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Song Picker ───────────────────────────────────────────────────────────────

class _SongPickerView extends StatefulWidget {
  const _SongPickerView({required this.state});
  final TransferState state;

  @override
  State<_SongPickerView> createState() => _SongPickerViewState();
}

class _SongPickerViewState extends State<_SongPickerView> {
  final Set<int> _selectedIds = {};
  List<SongModel> _allSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Pre-select previously picked songs
    for (final s in widget.state.selectedSongs) {
      _selectedIds.add(s.id);
    }
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final query = oaq.OnAudioQuery();
    final raw = await query.querySongs(
      sortType: oaq.SongSortType.TITLE,
      orderType: oaq.OrderType.ASC_OR_SMALLER,
      uriType: oaq.UriType.EXTERNAL,
      ignoreCase: true,
    );
    if (!mounted) return;
    setState(() {
      _allSongs = raw
          .map((s) => SongModel(
                id: s.id,
                title: s.title,
                artist: s.artist ?? 'Unknown',
                album: s.album ?? 'Unknown',
                data: s.data,
                duration: s.duration ?? 0,
                size: s.size,
                dateAdded: s.dateAdded ?? 0,
              ))
          .toList();
      _loading = false;
    });
  }

  void _toggleAll(bool select) {
    setState(() {
      if (select) {
        _selectedIds.addAll(_allSongs.map((s) => s.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _confirm(BuildContext context) {
    final songs =
        _allSongs.where((s) => _selectedIds.contains(s.id)).toList();
    context.read<TransferBloc>().add(TransferSongsSelected(songs));
    context.read<TransferBloc>().add(const TransferSendStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header
        _ScreenHeader(
          title: 'SELECT SONGS',
          subtitle: '${_selectedIds.length} selected',
          onBack: () {
            context.read<TransferBloc>().add(const TransferSessionReset());
            Navigator.of(context).pop();
          },
          actions: _loading
              ? const []
              : [
                  _HeaderBtn(label: 'ALL', onTap: () => _toggleAll(true)),
                  AppSpacing.hGap(AppSpacing.xs),
                  _HeaderBtn(label: 'NONE', onTap: () => _toggleAll(false)),
                ],
        ),

        // ── Songs list
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _allSongs.length,
                  itemBuilder: (_, i) {
                    final song = _allSongs[i];
                    final selected = _selectedIds.contains(song.id);
                    return _SongPickItem(
                      song: song,
                      selected: selected,
                      onToggle: () => setState(() {
                        if (selected) {
                          _selectedIds.remove(song.id);
                        } else {
                          _selectedIds.add(song.id);
                        }
                      }),
                    );
                  },
                ),
        ),

        // ── Confirm button
        if (_selectedIds.isNotEmpty)
          _BottomActionBar(
            label:
                'SEND ${_selectedIds.length} SONG${_selectedIds.length > 1 ? "S" : ""}',
            icon: Icons.send,
            onTap: () => _confirm(context),
          ),
      ],
    );
  }
}

// ── Advertising view (Nearby) ─────────────────────────────────────────────────

class _AdvertisingView extends StatelessWidget {
  const _AdvertisingView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScreenHeader(
          title: 'WAITING FOR RECEIVER',
          subtitle:
              'NEARBY SHARE • ${state.selectedSongs.length} SONGS READY',
          onBack: () {
            context.read<TransferBloc>().add(const TransferSessionReset());
            Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingIcon(icon: Icons.sensors, color: AppColors.primary),
                AppSpacing.vGap(AppSpacing.lg),
                Text(
                  'ADVERTISING…',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                AppSpacing.vGap(AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Make sure the other device has the app open '
                    'and taps RECEIVE → Nearby Share.',
                    style: AppTextStyles.bodySm,
                    textAlign: TextAlign.center,
                  ),
                ),
                AppSpacing.vGap(AppSpacing.lg),
                TransferInfoChip(
                  label: '${state.selectedSongs.length} songs queued',
                  icon: Icons.music_note,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── QR Code view (WiFi) ───────────────────────────────────────────────────────

class _QrCodeView extends StatelessWidget {
  const _QrCodeView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final payload = state.wifiQrPayload;
    return Column(
      children: [
        _ScreenHeader(
          title: 'SCAN TO RECEIVE',
          subtitle:
              'WIFI TRANSFER • ${state.selectedSongs.length} SONGS READY',
          onBack: () {
            context.read<TransferBloc>().add(const TransferSessionReset());
            Navigator.of(context).pop();
          },
        ),
        Expanded(
          child: Center(
            child: payload == null
                ? const CircularProgressIndicator(color: AppColors.primary)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: AppColors.border, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowNeutral,
                              offset: Offset(6, 6),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.onSurface,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      AppSpacing.vGap(AppSpacing.lg),
                      Text(
                        'SERVER RUNNING',
                        style: AppTextStyles.headlineSm.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      AppSpacing.vGap(AppSpacing.sm),
                      TransferInfoChip(
                        label:
                            '${state.wifiIpAddress}:${state.wifiPort}',
                        icon: Icons.wifi,
                      ),
                      AppSpacing.vGap(AppSpacing.sm),
                      TransferInfoChip(
                        label:
                            '${state.selectedSongs.length} songs available',
                        icon: Icons.music_note,
                      ),
                      AppSpacing.vGap(AppSpacing.lg),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Open the app on the other device, tap RECEIVE → '
                          'Same Network, and scan this QR code.',
                          style: AppTextStyles.bodySm,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Connection pending (sender confirms receiver) ─────────────────────────────

class _ConnectionRequestView extends StatelessWidget {
  const _ConnectionRequestView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              color: AppColors.gold,
              child: const Icon(Icons.person,
                  size: 36, color: AppColors.onSurface),
            ),
            AppSpacing.vGap(AppSpacing.lg),
            Text(
              'CONNECTION REQUEST',
              style: AppTextStyles.headlineSm.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap(AppSpacing.sm),
            Text(
              '"${state.pendingConnectionName ?? "Unknown"}" wants to receive your songs.',
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap(AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: TransferBigButton(
                    label: 'REJECT',
                    color: AppColors.error,
                    onTap: () => context.read<TransferBloc>().add(
                          TransferConnectionRejected(
                              state.pendingConnectionId ?? ''),
                        ),
                  ),
                ),
                AppSpacing.hGap(AppSpacing.md),
                Expanded(
                  child: TransferBigButton(
                    label: 'ACCEPT',
                    color: AppColors.primary,
                    onTap: () => context.read<TransferBloc>().add(
                          TransferConnectionAccepted(
                              state.pendingConnectionId ?? ''),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Connecting ────────────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          AppSpacing.vGap(AppSpacing.lg),
          Text(
            'CONNECTING…',
            style: AppTextStyles.headlineSm.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          if (state.connectedEndpointName != null) ...[
            AppSpacing.vGap(AppSpacing.sm),
            TransferInfoChip(
              label: state.connectedEndpointName!,
              icon: Icons.devices,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Failed ────────────────────────────────────────────────────────────────────

class _FailedView extends StatelessWidget {
  const _FailedView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              color: AppColors.error,
              child: const Icon(Icons.error, size: 36, color: Colors.white),
            ),
            AppSpacing.vGap(AppSpacing.lg),
            Text(
              'TRANSFER FAILED',
              style: AppTextStyles.headlineSm.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            AppSpacing.vGap(AppSpacing.sm),
            Text(
              state.errorMessage ?? 'Unknown error',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap(AppSpacing.xl),
            TransferBigButton(
              label: 'TRY AGAIN',
              color: AppColors.primary,
              onTap: () {
                context.read<TransferBloc>().add(const TransferSessionReset());
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared header ─────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18, color: AppColors.onSurface),
            ),
          ),
          AppSpacing.hGap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineSm
                      .copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Song pick item ────────────────────────────────────────────────────────────

class _SongPickItem extends StatelessWidget {
  const _SongPickItem({
    required this.song,
    required this.selected,
    required this.onToggle,
  });

  final SongModel song;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      overlayColor: WidgetStateProperty.all(AppColors.hoverFill),
      child: Container(
        padding: AppSpacing.listItemPadding,
        decoration: const BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            AppSpacing.hGap(AppSpacing.md),
            // Artwork
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border:
                    Border.all(color: AppColors.outlineVariant, width: 1),
                color: AppColors.surfaceContainerHigh,
              ),
              child: oaq.QueryArtworkWidget(
                id: song.id,
                type: oaq.ArtworkType.AUDIO,
                artworkWidth: 44,
                artworkHeight: 44,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                nullArtworkWidget: const Icon(
                  Icons.music_note,
                  size: 20,
                  color: AppColors.outline,
                ),
              ),
            ),
            AppSpacing.hGap(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: AppTextStyles.labelSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              _fmtSize(song.size),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TransferBigButton(
        label: label,
        color: AppColors.primary,
        icon: icon,
        onTap: onTap,
      ),
    );
  }
}

// ── Pulsing icon ──────────────────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.12),
          border: Border.all(color: widget.color, width: 3),
        ),
        child: Icon(widget.icon, size: 48, color: widget.color),
      ),
    );
  }
}
