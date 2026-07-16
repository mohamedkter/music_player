import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/transfer_bloc.dart';
import 'widgets/transfer_progress_list.dart';
import 'widgets/transfer_shared_widgets.dart';

/// Receiver screen — discover sender (Nearby) or scan QR (WiFi) → download.
class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

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
              TransferStatus.idle ||
              TransferStatus.selectingMethod =>
                _MethodPickerView(state: state),
              TransferStatus.discovering => _DiscoveringView(state: state),
              TransferStatus.connecting => _ConnectingView(state: state),
              TransferStatus.transferring ||
              TransferStatus.completed =>
                TransferProgressList(state: state),
              TransferStatus.failed => _FailedView(state: state),
              _ => _MethodPickerView(state: state),
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
          'RECEIVED',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${state.completedCount} songs saved to your device.\n'
          'Check "MusicPlayerTransfer" folder in storage.'
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

// ── Method Picker ─────────────────────────────────────────────────────────────

class _MethodPickerView extends StatelessWidget {
  const _MethodPickerView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReceiveHeader(
          subtitle: 'CHOOSE HOW TO RECEIVE',
          onBack: () {
            context.read<TransferBloc>().add(const TransferSessionReset());
            Navigator.of(context).pop();
          },
        ),
        AppSpacing.vGap(AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'RECEIVE METHOD',
            style: AppTextStyles.labelSm.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        AppSpacing.vGap(AppSpacing.sm),
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _ReceiveMethodTile(
                icon: Icons.sensors,
                title: 'NEARBY SHARE',
                subtitle:
                    'Bluetooth / WiFi Direct — scan for nearby senders',
                color: AppColors.primary,
                onTap: () {
                  context.read<TransferBloc>()
                    ..add(TransferMethodSelected(TransferMethod.nearby))
                    ..add(const TransferDiscoveryStarted());
                },
              ),
              AppSpacing.vGap(AppSpacing.md),
              _ReceiveMethodTile(
                icon: Icons.qr_code_scanner,
                title: 'SCAN QR CODE',
                subtitle:
                    "Same WiFi network — scan the QR shown on the sender's screen",
                color: AppColors.secondary,
                onTap: () {
                  context
                      .read<TransferBloc>()
                      .add(TransferMethodSelected(TransferMethod.wifi));
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TransferBloc>(),
                        child: const _QrScannerScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Discovering (Nearby) ──────────────────────────────────────────────────────

class _DiscoveringView extends StatelessWidget {
  const _DiscoveringView({required this.state});
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReceiveHeader(
          subtitle: 'NEARBY SHARE • SCANNING…',
          onBack: () {
            context.read<TransferBloc>().add(const TransferSessionReset());
            Navigator.of(context).pop();
          },
        ),
        if (state.discoveredEndpoints.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ScanAnimation(),
                  AppSpacing.vGap(AppSpacing.lg),
                  Text(
                    'SCANNING FOR SENDERS…',
                    style: AppTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  AppSpacing.vGap(AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Ask the sender to open the app, select songs, '
                      'and tap SEND → Nearby Share.',
                      style: AppTextStyles.bodySm,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '${state.discoveredEndpoints.length} '
              'SENDER${state.discoveredEndpoints.length > 1 ? "S" : ""} FOUND',
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.discoveredEndpoints.length,
              itemBuilder: (_, i) {
                final endpoint = state.discoveredEndpoints[i];
                return _EndpointTile(
                  name: endpoint.name,
                  onConnect: () => context.read<TransferBloc>().add(
                        TransferEndpointSelected(
                          endpointId: endpoint.id,
                          endpointName: endpoint.name,
                        ),
                      ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── QR Scanner screen ─────────────────────────────────────────────────────────

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _scanned = false;
  final MobileScannerController _ctrl = MobileScannerController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    if (!raw.startsWith('music_player|')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid QR code — not a Music Player transfer code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _scanned = true;
    context.read<TransferBloc>().add(TransferQrScanned(raw));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(controller: _ctrl, onDetect: _onDetect),

            // ── Overlay
            Column(
              children: [
                // Header
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          color: Colors.white12,
                          child: const Icon(Icons.close,
                              size: 20, color: Colors.white),
                        ),
                      ),
                      AppSpacing.hGap(AppSpacing.md),
                      Text(
                        'SCAN QR CODE',
                        style: AppTextStyles.headlineSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Corner brackets
                Center(
                  child: CustomPaint(
                    painter: _ScannerBracketsPainter(),
                    size: const Size(220, 220),
                  ),
                ),

                const Spacer(),

                // Bottom hint
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    "Point the camera at the QR code shown on the sender's device",
                    style:
                        AppTextStyles.bodySm.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
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
          if (state.wifiIpAddress != null) ...[
            AppSpacing.vGap(AppSpacing.sm),
            TransferInfoChip(
              label: '${state.wifiIpAddress}:${state.wifiPort}',
              icon: Icons.wifi,
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
              child:
                  const Icon(Icons.error, size: 36, color: Colors.white),
            ),
            AppSpacing.vGap(AppSpacing.lg),
            Text(
              'RECEIVE FAILED',
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

class _ReceiveHeader extends StatelessWidget {
  const _ReceiveHeader({required this.subtitle, required this.onBack});
  final String subtitle;
  final VoidCallback onBack;

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
                  'RECEIVE SONGS',
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
        ],
      ),
    );
  }
}

// ── Receive method tile ───────────────────────────────────────────────────────

class _ReceiveMethodTile extends StatelessWidget {
  const _ReceiveMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowNeutral,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              color: color,
              child: Icon(icon, size: 26, color: Colors.white),
            ),
            AppSpacing.hGap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.vGap(2),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Discovered endpoint tile ──────────────────────────────────────────────────

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.name, required this.onConnect});
  final String name;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowNeutral, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            color: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.phone_android,
                size: 22, color: AppColors.primary),
          ),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'TAP TO CONNECT',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Text(
                'CONNECT',
                style: AppTextStyles.labelSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan animation ────────────────────────────────────────────────────────────

class _ScanAnimation extends StatefulWidget {
  const _ScanAnimation();

  @override
  State<_ScanAnimation> createState() => _ScanAnimationState();
}

class _ScanAnimationState extends State<_ScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
        child: const Icon(Icons.sensors,
            size: 40, color: AppColors.primary),
      ),
    );
  }
}

// ── QR Scanner corner brackets ────────────────────────────────────────────────

class _ScannerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;

    const len = 32.0;
    final r = Rect.fromLTWH(0, 0, size.width, size.height);

    // Top-left
    canvas.drawLine(r.topLeft, r.topLeft.translate(len, 0), paint);
    canvas.drawLine(r.topLeft, r.topLeft.translate(0, len), paint);
    // Top-right
    canvas.drawLine(r.topRight, r.topRight.translate(-len, 0), paint);
    canvas.drawLine(r.topRight, r.topRight.translate(0, len), paint);
    // Bottom-left
    canvas.drawLine(r.bottomLeft, r.bottomLeft.translate(len, 0), paint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft.translate(0, -len), paint);
    // Bottom-right
    canvas.drawLine(r.bottomRight, r.bottomRight.translate(-len, 0), paint);
    canvas.drawLine(r.bottomRight, r.bottomRight.translate(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
