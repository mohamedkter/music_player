part of 'transfer_bloc.dart';

// ── Enumerations ──────────────────────────────────────────────────────────────

enum TransferMethod { nearby, wifi }

enum TransferRole { sender, receiver }

enum TransferStatus {
  idle,
  selectingMethod,
  selectingSongs,    // sender: picking songs
  advertising,       // sender: waiting for connections (Nearby)
  serverRunning,     // sender: HTTP server active (WiFi)
  discovering,       // receiver: scanning
  connectionPending, // sender: got a request, waiting for user accept
  connecting,        // both: handshake in progress
  transferring,      // both: data in flight
  completed,
  failed,
}

// ── Per-song progress model ───────────────────────────────────────────────────

class SongTransferProgress extends Equatable {
  const SongTransferProgress({
    required this.song,
    this.progress = 0.0,
    this.done = false,
    this.failed = false,
    this.failReason,
  });

  final SongModel song;
  final double progress; // 0.0 → 1.0
  final bool done;
  final bool failed;
  final String? failReason;

  SongTransferProgress copyWith({
    double? progress,
    bool? done,
    bool? failed,
    String? failReason,
  }) {
    return SongTransferProgress(
      song: song,
      progress: progress ?? this.progress,
      done: done ?? this.done,
      failed: failed ?? this.failed,
      failReason: failReason ?? this.failReason,
    );
  }

  @override
  List<Object?> get props => [song, progress, done, failed, failReason];
}

// ── Discovered endpoint model ─────────────────────────────────────────────────

class DiscoveredEndpoint extends Equatable {
  const DiscoveredEndpoint({required this.id, required this.name});
  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

// ── Main state ────────────────────────────────────────────────────────────────

class TransferState extends Equatable {
  const TransferState({
    this.status = TransferStatus.idle,
    this.method,
    this.role,
    this.selectedSongs = const [],
    this.songProgresses = const [],
    this.discoveredEndpoints = const [],
    this.pendingConnectionId,
    this.pendingConnectionName,
    this.connectedEndpointId,
    this.connectedEndpointName,
    this.wifiIpAddress,
    this.wifiPort,
    this.errorMessage,
    this.completedCount = 0,
    this.failedCount = 0,
  });

  final TransferStatus status;
  final TransferMethod? method;
  final TransferRole? role;

  /// Songs the sender wants to share.
  final List<SongModel> selectedSongs;

  /// Per-song progress list (mirrors [selectedSongs]).
  final List<SongTransferProgress> songProgresses;

  /// Nearby endpoints visible to the receiver.
  final List<DiscoveredEndpoint> discoveredEndpoints;

  /// Incoming connection waiting for user accept/reject (sender side).
  final String? pendingConnectionId;
  final String? pendingConnectionName;

  /// Active connected endpoint.
  final String? connectedEndpointId;
  final String? connectedEndpointName;

  /// WiFi-mode server address shown as QR code.
  final String? wifiIpAddress;
  final int? wifiPort;

  final String? errorMessage;
  final int completedCount;
  final int failedCount;

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isIdle => status == TransferStatus.idle;
  bool get isTransferring => status == TransferStatus.transferring;
  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;

  /// Overall progress 0.0–1.0 averaged across all songs.
  double get overallProgress {
    if (songProgresses.isEmpty) return 0.0;
    final sum = songProgresses.fold(0.0, (acc, p) => acc + p.progress);
    return sum / songProgresses.length;
  }

  /// QR payload for WiFi mode: "music_player|{ip}|{port}"
  String? get wifiQrPayload {
    if (wifiIpAddress == null || wifiPort == null) return null;
    return 'music_player|$wifiIpAddress|$wifiPort';
  }

  TransferState copyWith({
    TransferStatus? status,
    TransferMethod? method,
    TransferRole? role,
    List<SongModel>? selectedSongs,
    List<SongTransferProgress>? songProgresses,
    List<DiscoveredEndpoint>? discoveredEndpoints,
    String? pendingConnectionId,
    String? pendingConnectionName,
    String? connectedEndpointId,
    String? connectedEndpointName,
    String? wifiIpAddress,
    int? wifiPort,
    String? errorMessage,
    int? completedCount,
    int? failedCount,
    bool clearPending = false,
    bool clearError = false,
    bool clearWifi = false,
  }) {
    return TransferState(
      status: status ?? this.status,
      method: method ?? this.method,
      role: role ?? this.role,
      selectedSongs: selectedSongs ?? this.selectedSongs,
      songProgresses: songProgresses ?? this.songProgresses,
      discoveredEndpoints: discoveredEndpoints ?? this.discoveredEndpoints,
      pendingConnectionId:
          clearPending ? null : pendingConnectionId ?? this.pendingConnectionId,
      pendingConnectionName: clearPending
          ? null
          : pendingConnectionName ?? this.pendingConnectionName,
      connectedEndpointId:
          connectedEndpointId ?? this.connectedEndpointId,
      connectedEndpointName:
          connectedEndpointName ?? this.connectedEndpointName,
      wifiIpAddress:
          clearWifi ? null : wifiIpAddress ?? this.wifiIpAddress,
      wifiPort: clearWifi ? null : wifiPort ?? this.wifiPort,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        method,
        role,
        selectedSongs,
        songProgresses,
        discoveredEndpoints,
        pendingConnectionId,
        pendingConnectionName,
        connectedEndpointId,
        connectedEndpointName,
        wifiIpAddress,
        wifiPort,
        errorMessage,
        completedCount,
        failedCount,
      ];
}
