import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/transfer_bloc.dart';
import '../service/nearby_transfer_service.dart';
import '../service/wifi_transfer_service.dart';
import '../service/transfer_permission_service.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

/// Entry-point screen: pick a method (Nearby / WiFi) and a role (Send / Receive).
class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransferBloc(
        nearbyService: sl<NearbyTransferService>(),
        wifiService: sl<WifiTransferService>(),
      ),
      child: const _TransferView(),
    );
  }
}

class _TransferView extends StatelessWidget {
  const _TransferView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Brutalist header ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            border:
                                Border.all(color: AppColors.border, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowNeutral,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back,
                              size: 20, color: AppColors.onSurface),
                        ),
                      ),
                      AppSpacing.hGap(AppSpacing.md),
                      Expanded(
                        child: Text(
                          'SHARE MUSIC',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          border:
                              Border.all(color: AppColors.border, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowNeutral,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.share,
                            size: 20, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Subtitle ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'TRANSFER SONGS DIRECTLY TO ANOTHER DEVICE\nNO INTERNET REQUIRED',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: AppSpacing.vGap(AppSpacing.lg)),

              // ── Method cards ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'SELECT TRANSFER METHOD',
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: AppSpacing.vGap(AppSpacing.sm)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _MethodCard(
                    method: TransferMethod.nearby,
                    title: 'NEARBY SHARE',
                    subtitle:
                        'Bluetooth / WiFi Direct — works without any network',
                    icon: Icons.sensors,
                    accentColor: AppColors.primary,
                    badge: 'RECOMMENDED',
                  ),
                ),
              ),

              SliverToBoxAdapter(child: AppSpacing.vGap(AppSpacing.md)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _MethodCard(
                    method: TransferMethod.wifi,
                    title: 'SAME NETWORK (QR)',
                    subtitle:
                        'HTTP over local WiFi — both devices on same router',
                    icon: Icons.qr_code_scanner,
                    accentColor: AppColors.secondary,
                    badge: 'FAST',
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Method selection card ─────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badge,
  });

  final TransferMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferBloc, TransferState>(
      buildWhen: (prev, next) => prev.method != next.method,
      builder: (context, state) {
        final isSelected = state.method == method;
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLowest,
            border: Border.all(
              color: isSelected ? accentColor : AppColors.border,
              width: isSelected ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? accentColor : AppColors.shadowNeutral,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row
              GestureDetector(
                onTap: () => context
                    .read<TransferBloc>()
                    .add(TransferMethodSelected(method)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        color: accentColor,
                        child: Icon(icon,
                            color: Colors.white, size: 24),
                      ),
                      AppSpacing.hGap(AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.hGap(AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  color: accentColor,
                                  child: Text(
                                    badge,
                                    style: AppTextStyles.labelSm.copyWith(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.vGap(2),
                            Text(
                              subtitle,
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : AppColors.outlineVariant,
                            width: 2,
                          ),
                          color: isSelected ? accentColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Action buttons (only visible when selected)
              if (isSelected) ...[
                Container(
                  height: 1,
                  color: AppColors.outlineVariant,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'SEND',
                          icon: Icons.upload,
                          color: accentColor,
                          onTap: () => _openSend(context),
                        ),
                      ),
                      AppSpacing.hGap(AppSpacing.sm),
                      Expanded(
                        child: _ActionButton(
                          label: 'RECEIVE',
                          icon: Icons.download,
                          color: AppColors.onSurface,
                          onTap: () => _openReceive(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openSend(BuildContext context) {
    _requestPermissionsThen(
      context: context,
      method: method,
      onGranted: () {
        final bloc = context.read<TransferBloc>();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: const SendScreen(),
            ),
          ),
        );
      },
    );
  }

  void _openReceive(BuildContext context) {
    _requestPermissionsThen(
      context: context,
      method: method,
      onGranted: () {
        final bloc = context.read<TransferBloc>();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: const ReceiveScreen(),
            ),
          ),
        );
      },
    );
  }

  /// Requests the correct runtime permissions based on [method],
  /// then calls [onGranted] if all are approved.
  Future<void> _requestPermissionsThen({
    required BuildContext context,
    required TransferMethod method,
    required VoidCallback onGranted,
  }) async {
    final result = method == TransferMethod.nearby
        ? await TransferPermissionService.requestNearbyPermissions()
        : await TransferPermissionService.requestWifiPermissions();

    if (!context.mounted) return;

    if (result.isGranted) {
      onGranted();
      return;
    }

    // Show appropriate dialog
    await showDialog<void>(
      context: context,
      builder: (_) => _PermissionDeniedDialog(
        message: result.message,
        showSettingsButton: result.isPermanentlyDenied,
      ),
    );
  }
}

// ── Permission denied dialog ─────────────────────────────────────────────────

class _PermissionDeniedDialog extends StatelessWidget {
  const _PermissionDeniedDialog({
    required this.message,
    required this.showSettingsButton,
  });

  final String message;
  final bool showSettingsButton;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.border, width: 2),
      ),
      title: Text(
        'PERMISSIONS REQUIRED',
        style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w900),
      ),
      content: Text(message, style: AppTextStyles.bodyMd),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (showSettingsButton)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              TransferPermissionService.openSettings();
            },
            child: Text(
              'OPEN SETTINGS',
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

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowNeutral,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            AppSpacing.hGap(AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
