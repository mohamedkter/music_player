import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/logger.dart';

/// Handles all runtime permissions required by the Transfer feature.
///
/// Must be called before starting any Nearby or WiFi transfer.
/// Automatically adapts the permission list based on the Android SDK version:
///   - Android 13+ (SDK 33+) → uses [Permission.nearbyWifiDevices]
///   - Android 12 and below  → uses [Permission.location] only
class TransferPermissionService {
  static const _tag = 'TransferPermissionService';

  // ── SDK detection ──────────────────────────────────────────────────────────

  static int? _cachedSdk;

  static Future<int> _androidSdk() async {
    if (_cachedSdk != null) return _cachedSdk!;
    final info = await DeviceInfoPlugin().androidInfo;
    _cachedSdk = info.version.sdkInt;
    AppLogger.debug('Android SDK: $_cachedSdk', tag: _tag);
    return _cachedSdk!;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Request all permissions needed for Nearby Connections (BT + WiFi Direct).
  static Future<PermissionResult> requestNearbyPermissions() async {
    if (!Platform.isAndroid) return PermissionResult.granted();

    final sdk = await _androidSdk();
    final permissions = await _nearbyPermissions(sdk);

    AppLogger.info(
      'Requesting ${permissions.length} Nearby permissions (SDK $sdk)…',
      tag: _tag,
    );

    final statuses = await permissions.request();
    return _evaluate(statuses);
  }

  /// Request permissions needed for WiFi LAN transfer.
  static Future<PermissionResult> requestWifiPermissions() async {
    if (!Platform.isAndroid) return PermissionResult.granted();

    final sdk = await _androidSdk();
    final permissions = _wifiPermissions(sdk);

    AppLogger.info(
      'Requesting ${permissions.length} WiFi permissions (SDK $sdk)…',
      tag: _tag,
    );

    final statuses = await permissions.request();
    return _evaluate(statuses);
  }

  /// Open app settings so the user can manually grant denied permissions.
  static Future<bool> openSettings() => openAppSettings();

  // ── Permission sets ────────────────────────────────────────────────────────

  static Future<List<Permission>> _nearbyPermissions(int sdk) async {
    final list = <Permission>[
      Permission.location, // ACCESS_FINE_LOCATION — always required
    ];

    if (sdk >= 31) {
      // Android 12+ — granular Bluetooth permissions
      list.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ]);
    }

    if (sdk >= 33) {
      // Android 13+ — NEARBY_WIFI_DEVICES replaces location for WiFi scanning
      list.add(Permission.nearbyWifiDevices);
    }

    return list;
  }

  static List<Permission> _wifiPermissions(int sdk) {
    if (sdk >= 33) {
      return [Permission.nearbyWifiDevices];
    }
    // Android 12 and below — location is needed for WiFi info
    return [Permission.location];
  }

  // ── Evaluation ────────────────────────────────────────────────────────────

  static PermissionResult _evaluate(
      Map<Permission, PermissionStatus> statuses) {
    final denied = <Permission>[];
    final permanentlyDenied = <Permission>[];

    for (final entry in statuses.entries) {
      final perm = entry.key;
      final status = entry.value;

      AppLogger.debug('${perm.toString()}: ${status.name}', tag: _tag);

      if (status.isPermanentlyDenied) {
        permanentlyDenied.add(perm);
      } else if (!status.isGranted) {
        denied.add(perm);
      }
    }

    if (permanentlyDenied.isNotEmpty) {
      AppLogger.warning(
        'Permanently denied: ${permanentlyDenied.map((p) => p.toString()).join(', ')}',
        tag: _tag,
      );
      return PermissionResult.permanentlyDenied(permanentlyDenied);
    }

    if (denied.isNotEmpty) {
      AppLogger.warning(
        'Denied: ${denied.map((p) => p.toString()).join(', ')}',
        tag: _tag,
      );
      return PermissionResult.denied(denied);
    }

    AppLogger.info('All permissions granted ✓', tag: _tag);
    return PermissionResult.granted();
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

enum PermissionResultStatus { granted, denied, permanentlyDenied }

class PermissionResult {
  const PermissionResult._({
    required this.status,
    this.deniedPermissions = const [],
  });

  factory PermissionResult.granted() =>
      const PermissionResult._(status: PermissionResultStatus.granted);

  factory PermissionResult.denied(List<Permission> perms) =>
      PermissionResult._(
        status: PermissionResultStatus.denied,
        deniedPermissions: perms,
      );

  factory PermissionResult.permanentlyDenied(List<Permission> perms) =>
      PermissionResult._(
        status: PermissionResultStatus.permanentlyDenied,
        deniedPermissions: perms,
      );

  final PermissionResultStatus status;
  final List<Permission> deniedPermissions;

  bool get isGranted => status == PermissionResultStatus.granted;
  bool get isDenied => status == PermissionResultStatus.denied;
  bool get isPermanentlyDenied =>
      status == PermissionResultStatus.permanentlyDenied;

  /// Human-readable message to show in a dialog/snackbar.
  String get message {
    switch (status) {
      case PermissionResultStatus.granted:
        return 'All permissions granted.';
      case PermissionResultStatus.denied:
        return 'Some permissions were denied. Please grant them to use transfer.';
      case PermissionResultStatus.permanentlyDenied:
        return 'Permissions were permanently denied. '
            'Please enable them in App Settings.';
    }
  }
}
