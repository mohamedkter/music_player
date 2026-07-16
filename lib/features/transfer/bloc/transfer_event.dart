part of 'transfer_bloc.dart';

/// All events the [TransferBloc] can receive.
sealed class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

// ── Method Selection ──────────────────────────────────────────────────────────

/// User chose a transfer method (Nearby or WiFi).
class TransferMethodSelected extends TransferEvent {
  const TransferMethodSelected(this.method);
  final TransferMethod method;

  @override
  List<Object?> get props => [method];
}

// ── Send side ─────────────────────────────────────────────────────────────────

/// User selected songs to send.
class TransferSongsSelected extends TransferEvent {
  const TransferSongsSelected(this.songs);
  final List<SongModel> songs;

  @override
  List<Object?> get props => [songs];
}

/// Start advertising / start HTTP server so a receiver can connect.
class TransferSendStarted extends TransferEvent {
  const TransferSendStarted();
}

/// Sender accepted a connection request from [endpointId].
class TransferConnectionAccepted extends TransferEvent {
  const TransferConnectionAccepted(this.endpointId);
  final String endpointId;

  @override
  List<Object?> get props => [endpointId];
}

/// Sender rejected a connection request.
class TransferConnectionRejected extends TransferEvent {
  const TransferConnectionRejected(this.endpointId);
  final String endpointId;

  @override
  List<Object?> get props => [endpointId];
}

// ── Receive side ──────────────────────────────────────────────────────────────

/// Start scanning for nearby senders.
class TransferDiscoveryStarted extends TransferEvent {
  const TransferDiscoveryStarted();
}

/// User tapped on a discovered endpoint / scanned a QR code.
class TransferEndpointSelected extends TransferEvent {
  const TransferEndpointSelected({
    required this.endpointId,
    required this.endpointName,
  });
  final String endpointId;
  final String endpointName;

  @override
  List<Object?> get props => [endpointId, endpointName];
}

/// User scanned a QR code from the WiFi transfer method.
class TransferQrScanned extends TransferEvent {
  const TransferQrScanned(this.payload);
  final String payload;

  @override
  List<Object?> get props => [payload];
}

// ── Internal progress events (emitted by services) ────────────────────────────

/// A nearby device was discovered.
class _NearbyEndpointFound extends TransferEvent {
  const _NearbyEndpointFound({required this.id, required this.name});
  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// A nearby device disappeared.
class _NearbyEndpointLost extends TransferEvent {
  const _NearbyEndpointLost(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// Nearby connection request received by the sender side.
class _NearbyConnectionRequested extends TransferEvent {
  const _NearbyConnectionRequested({required this.id, required this.name});
  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Connection result (accepted / rejected / error).
class _NearbyConnectionResult extends TransferEvent {
  const _NearbyConnectionResult({required this.id, required this.success});
  final String id;
  final bool success;

  @override
  List<Object?> get props => [id, success];
}

/// Transfer progress updated for a specific song [index].
class _TransferProgressUpdated extends TransferEvent {
  const _TransferProgressUpdated({required this.index, required this.progress});
  final int index;
  final double progress;

  @override
  List<Object?> get props => [index, progress];
}

/// A single song finished transferring successfully.
class _SongTransferCompleted extends TransferEvent {
  const _SongTransferCompleted(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

/// A song transfer failed.
class _SongTransferFailed extends TransferEvent {
  const _SongTransferFailed({required this.index, required this.reason});
  final int index;
  final String reason;

  @override
  List<Object?> get props => [index, reason];
}

/// All songs finished (or failed) — transfer session complete.
class _TransferSessionCompleted extends TransferEvent {
  const _TransferSessionCompleted();
}

/// An error occurred at any point.
class _TransferErrorOccurred extends TransferEvent {
  const _TransferErrorOccurred(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// ── Cleanup ───────────────────────────────────────────────────────────────────

/// Stop all active connections and reset to idle.
class TransferSessionReset extends TransferEvent {
  const TransferSessionReset();
}
