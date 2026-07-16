import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/song_model.dart';
import '../../../core/utils/logger.dart';
import '../service/nearby_transfer_service.dart';
import '../service/wifi_transfer_service.dart';

part 'transfer_event.dart';
part 'transfer_state.dart';

/// Manages the entire file-sharing session lifecycle.
///
/// Supports two transport modes:
///  - [TransferMethod.nearby]  → Google Nearby Connections (BT / WiFi Direct)
///  - [TransferMethod.wifi]    → Local HTTP server + QR discovery
///
/// The BLoC is stateless between sessions: every [TransferSessionReset] returns
/// the state to [TransferStatus.idle] and disposes all service resources.
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc({
    required NearbyTransferService nearbyService,
    required WifiTransferService wifiService,
  })  : _nearby = nearbyService,
        _wifi = wifiService,
        super(const TransferState()) {
    // ── Event handlers ────────────────────────────────────────────────────
    on<TransferMethodSelected>(_onMethodSelected);
    on<TransferSongsSelected>(_onSongsSelected);
    on<TransferSendStarted>(_onSendStarted);
    on<TransferConnectionAccepted>(_onConnectionAccepted);
    on<TransferConnectionRejected>(_onConnectionRejected);
    on<TransferDiscoveryStarted>(_onDiscoveryStarted);
    on<TransferEndpointSelected>(_onEndpointSelected);
    on<TransferQrScanned>(_onQrScanned);
    on<TransferSessionReset>(_onReset);

    // internal events
    on<_NearbyEndpointFound>(_onEndpointFound);
    on<_NearbyEndpointLost>(_onEndpointLost);
    on<_NearbyConnectionRequested>(_onConnectionRequested);
    on<_NearbyConnectionResult>(_onConnectionResult);
    on<_TransferProgressUpdated>(_onProgressUpdated);
    on<_SongTransferCompleted>(_onSongCompleted);
    on<_SongTransferFailed>(_onSongFailed);
    on<_TransferSessionCompleted>(_onSessionCompleted);
    on<_TransferErrorOccurred>(_onError);

    _bindNearbyCallbacks();
    _bindWifiCallbacks();
  }

  final NearbyTransferService _nearby;
  final WifiTransferService _wifi;

  static const _tag = 'TransferBloc';

  // ── Callback binding ──────────────────────────────────────────────────────

  void _bindNearbyCallbacks() {
    _nearby.onEndpointFound = (id, name) =>
        add(_NearbyEndpointFound(id: id, name: name));

    _nearby.onEndpointLost = (id) => add(_NearbyEndpointLost(id));

    _nearby.onConnectionRequested = (id, name) =>
        add(_NearbyConnectionRequested(id: id, name: name));

    _nearby.onConnectionResult = (id, success) =>
        add(_NearbyConnectionResult(id: id, success: success));

    _nearby.onProgress = (index, progress) =>
        add(_TransferProgressUpdated(index: index, progress: progress));

    _nearby.onSongCompleted = (index) => add(_SongTransferCompleted(index));

    _nearby.onSongFailed = (index, reason) =>
        add(_SongTransferFailed(index: index, reason: reason));

    _nearby.onSessionCompleted = () => add(const _TransferSessionCompleted());

    _nearby.onError = (msg) => add(_TransferErrorOccurred(msg));
  }

  void _bindWifiCallbacks() {
    _wifi.onProgress = (index, progress) =>
        add(_TransferProgressUpdated(index: index, progress: progress));

    _wifi.onSongCompleted = (index) => add(_SongTransferCompleted(index));

    _wifi.onSongFailed = (index, reason) =>
        add(_SongTransferFailed(index: index, reason: reason));

    _wifi.onSessionCompleted = () => add(const _TransferSessionCompleted());

    _wifi.onError = (msg) => add(_TransferErrorOccurred(msg));
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onMethodSelected(
    TransferMethodSelected event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      status: TransferStatus.selectingMethod,
      method: event.method,
      clearError: true,
    ));
  }

  void _onSongsSelected(
    TransferSongsSelected event,
    Emitter<TransferState> emit,
  ) {
    final progresses = event.songs
        .map((s) => SongTransferProgress(song: s))
        .toList();

    emit(state.copyWith(
      status: TransferStatus.selectingSongs,
      role: TransferRole.sender,
      selectedSongs: event.songs,
      songProgresses: progresses,
      clearError: true,
    ));
  }

  Future<void> _onSendStarted(
    TransferSendStarted event,
    Emitter<TransferState> emit,
  ) async {
    if (state.selectedSongs.isEmpty) {
      emit(state.copyWith(errorMessage: 'No songs selected'));
      return;
    }

    try {
      if (state.method == TransferMethod.nearby) {
        await _nearby.startAdvertising(state.selectedSongs);
        emit(state.copyWith(
          status: TransferStatus.advertising,
          clearError: true,
        ));
      } else {
        final result = await _wifi.startServer(state.selectedSongs);
        emit(state.copyWith(
          status: TransferStatus.serverRunning,
          wifiIpAddress: result.ip,
          wifiPort: result.port,
          clearError: true,
        ));
      }
    } catch (e, st) {
      AppLogger.error('_onSendStarted', tag: _tag, error: e, stackTrace: st);
      emit(state.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onConnectionAccepted(
    TransferConnectionAccepted event,
    Emitter<TransferState> emit,
  ) {
    _nearby.acceptConnection(event.endpointId);
    emit(state.copyWith(
      status: TransferStatus.connecting,
      connectedEndpointId: event.endpointId,
      connectedEndpointName: state.pendingConnectionName,
      clearPending: true,
    ));
  }

  void _onConnectionRejected(
    TransferConnectionRejected event,
    Emitter<TransferState> emit,
  ) {
    _nearby.rejectConnection(event.endpointId);
    emit(state.copyWith(
      status: TransferStatus.advertising,
      clearPending: true,
    ));
  }

  Future<void> _onDiscoveryStarted(
    TransferDiscoveryStarted event,
    Emitter<TransferState> emit,
  ) async {
    try {
      await _nearby.startDiscovery();
      emit(state.copyWith(
        status: TransferStatus.discovering,
        role: TransferRole.receiver,
        discoveredEndpoints: const [],
        clearError: true,
      ));
    } catch (e, st) {
      AppLogger.error('_onDiscoveryStarted', tag: _tag, error: e, stackTrace: st);
      emit(state.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onEndpointSelected(
    TransferEndpointSelected event,
    Emitter<TransferState> emit,
  ) async {
    try {
      await _nearby.requestConnection(event.endpointId, event.endpointName);
      emit(state.copyWith(
        status: TransferStatus.connecting,
        connectedEndpointId: event.endpointId,
        connectedEndpointName: event.endpointName,
        clearError: true,
      ));
    } catch (e, st) {
      AppLogger.error('_onEndpointSelected', tag: _tag, error: e, stackTrace: st);
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onQrScanned(
    TransferQrScanned event,
    Emitter<TransferState> emit,
  ) async {
    // Payload format: "music_player|{ip}|{port}"
    final parts = event.payload.split('|');
    if (parts.length != 3 || parts[0] != 'music_player') {
      emit(state.copyWith(errorMessage: 'Invalid QR code'));
      return;
    }

    final ip = parts[1];
    final port = int.tryParse(parts[2]);
    if (port == null) {
      emit(state.copyWith(errorMessage: 'Invalid QR code: bad port'));
      return;
    }

    try {
      emit(state.copyWith(
        status: TransferStatus.connecting,
        role: TransferRole.receiver,
        wifiIpAddress: ip,
        wifiPort: port,
        clearError: true,
      ));
      await _wifi.downloadSongs(ip: ip, port: port);
    } catch (e, st) {
      AppLogger.error('_onQrScanned', tag: _tag, error: e, stackTrace: st);
      emit(state.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Internal event handlers ───────────────────────────────────────────────

  void _onEndpointFound(
    _NearbyEndpointFound event,
    Emitter<TransferState> emit,
  ) {
    final updated = List<DiscoveredEndpoint>.from(state.discoveredEndpoints)
      ..removeWhere((e) => e.id == event.id)
      ..add(DiscoveredEndpoint(id: event.id, name: event.name));

    emit(state.copyWith(discoveredEndpoints: updated));
  }

  void _onEndpointLost(
    _NearbyEndpointLost event,
    Emitter<TransferState> emit,
  ) {
    final updated = state.discoveredEndpoints
        .where((e) => e.id != event.id)
        .toList();
    emit(state.copyWith(discoveredEndpoints: updated));
  }

  void _onConnectionRequested(
    _NearbyConnectionRequested event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      status: TransferStatus.connectionPending,
      pendingConnectionId: event.id,
      pendingConnectionName: event.name,
    ));
  }

  void _onConnectionResult(
    _NearbyConnectionResult event,
    Emitter<TransferState> emit,
  ) {
    if (event.success) {
      final progresses = state.selectedSongs
          .map((s) => SongTransferProgress(song: s))
          .toList();

      emit(state.copyWith(
        status: TransferStatus.transferring,
        songProgresses: progresses,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        status: state.role == TransferRole.sender
            ? TransferStatus.advertising
            : TransferStatus.discovering,
        connectedEndpointId: null,
        connectedEndpointName: null,
        errorMessage: 'Connection failed',
      ));
    }
  }

  void _onProgressUpdated(
    _TransferProgressUpdated event,
    Emitter<TransferState> emit,
  ) {
    if (event.index >= state.songProgresses.length) return;
    final updated = List<SongTransferProgress>.from(state.songProgresses);
    updated[event.index] = updated[event.index].copyWith(
      progress: event.progress,
    );
    emit(state.copyWith(
      status: TransferStatus.transferring,
      songProgresses: updated,
    ));
  }

  void _onSongCompleted(
    _SongTransferCompleted event,
    Emitter<TransferState> emit,
  ) {
    if (event.index >= state.songProgresses.length) return;
    final updated = List<SongTransferProgress>.from(state.songProgresses);
    updated[event.index] =
        updated[event.index].copyWith(progress: 1.0, done: true);
    emit(state.copyWith(
      songProgresses: updated,
      completedCount: state.completedCount + 1,
    ));
  }

  void _onSongFailed(
    _SongTransferFailed event,
    Emitter<TransferState> emit,
  ) {
    if (event.index >= state.songProgresses.length) return;
    final updated = List<SongTransferProgress>.from(state.songProgresses);
    updated[event.index] = updated[event.index]
        .copyWith(failed: true, failReason: event.reason);
    emit(state.copyWith(
      songProgresses: updated,
      failedCount: state.failedCount + 1,
    ));
  }

  void _onSessionCompleted(
    _TransferSessionCompleted event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(status: TransferStatus.completed));
    _cleanup();
  }

  void _onError(
    _TransferErrorOccurred event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      status: TransferStatus.failed,
      errorMessage: event.message,
    ));
  }

  Future<void> _onReset(
    TransferSessionReset event,
    Emitter<TransferState> emit,
  ) async {
    await _cleanup();
    emit(const TransferState());
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> _cleanup() async {
    try {
      await Future.wait([
        _nearby.dispose(),
        _wifi.dispose(),
      ]);
    } catch (e) {
      AppLogger.warning('TransferBloc cleanup error: $e', tag: _tag);
    }
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}
