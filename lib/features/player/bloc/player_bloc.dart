import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../core/utils/logger.dart';

part 'player_event.dart';
part 'player_state.dart';

/// Singleton-style BLoC — provided at the root so it survives navigation.
/// Manages just_audio playback and exposes a clean state to all widgets.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc(this._repository) : super(const PlayerState()) {
    on<PlayerSongRequested>(_onSongRequested);
    on<PlayerTogglePlayPause>(_onToggle);
    on<PlayerSkipToNext>(_onNext);
    on<PlayerSkipToPrevious>(_onPrevious);
    on<PlayerSeekRequested>(_onSeek);
    on<PlayerShuffleToggled>(_onShuffle);
    on<PlayerRepeatToggled>(_onRepeat);
    on<PlayerSpeedChanged>(_onSpeedChanged);
    on<PlayerQueueReordered>(_onQueueReordered);
    on<PlayerSongRemovedFromQueue>(_onSongRemoved);
    on<PlayerFavoriteToggled>(_onFavoriteToggled);
    on<_PlayerPositionUpdated>(_onPositionUpdated);
    on<_PlayerStateUpdated>(_onStateUpdated);

    _subscribeToPlayer();
  }

  final SongRepository _repository;
  final AudioPlayer _player = AudioPlayer();
  late final ConcatenatingAudioSource _playlist;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlaybackEvent>? _eventSub;

  static const _tag = 'PlayerBloc';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void _subscribeToPlayer() {
    _posSub = _player.positionStream.listen(
      (pos) => add(_PlayerPositionUpdated(pos)),
      onError: (e) => AppLogger.error('Position stream error', tag: _tag, error: e),
    );

    _eventSub = _player.playbackEventStream.listen(
      (event) => add(_PlayerStateUpdated(
        isPlaying: _player.playing,
        duration: _player.duration ?? Duration.zero,
      )),
      onError: (e) => AppLogger.error('Playback event error', tag: _tag, error: e),
    );
  }

  @override
  Future<void> close() async {
    await _posSub?.cancel();
    await _eventSub?.cancel();
    await _player.dispose();
    super.close();
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onSongRequested(
    PlayerSongRequested event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final startIndex =
          event.queue.indexWhere((s) => s.id == event.song.id);
      final idx = startIndex < 0 ? 0 : startIndex;

      final sources = ConcatenatingAudioSource(
        children: event.queue
            .map((s) => AudioSource.uri(Uri.file(s.data)))
            .toList(),
      );

      await _player.setAudioSource(sources, initialIndex: idx);
      await _player.setSpeed(state.speed);
      await _player.play();

      emit(state.copyWith(
        currentSong: event.song,
        queue: event.queue,
        currentIndex: idx,
        isPlaying: true,
        isLoading: false,
        position: Duration.zero,
      ));

      // Record play for stats
      await _repository.recordPlay(event.song.id);
    } on PlayerException catch (e) {
      AppLogger.error('PlayerException', tag: _tag, error: e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Cannot play this file: ${e.message}',
      ));
    } catch (e, st) {
      AppLogger.error('_onSongRequested', tag: _tag, error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Playback error: $e',
      ));
    }
  }

  Future<void> _onToggle(
    PlayerTogglePlayPause event,
    Emitter<PlayerState> emit,
  ) async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _onNext(
    PlayerSkipToNext event,
    Emitter<PlayerState> emit,
  ) async {
    if (_player.hasNext) {
      await _player.seekToNext();
      final idx = _player.currentIndex ?? 0;
      final song = state.queue.length > idx ? state.queue[idx] : null;
      if (song != null) {
        emit(state.copyWith(currentSong: song, currentIndex: idx));
        await _repository.recordPlay(song.id);
      }
    }
  }

  Future<void> _onPrevious(
    PlayerSkipToPrevious event,
    Emitter<PlayerState> emit,
  ) async {
    // If > 3s into track, restart it; else go to previous
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
      final idx = _player.currentIndex ?? 0;
      final song = state.queue.length > idx ? state.queue[idx] : null;
      if (song != null) {
        emit(state.copyWith(currentSong: song, currentIndex: idx));
      }
    }
  }

  Future<void> _onSeek(
    PlayerSeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    await _player.seek(event.position);
  }

  Future<void> _onShuffle(
    PlayerShuffleToggled event,
    Emitter<PlayerState> emit,
  ) async {
    final newVal = !state.shuffleEnabled;
    await _player.setShuffleModeEnabled(newVal);
    emit(state.copyWith(shuffleEnabled: newVal));
  }

  Future<void> _onRepeat(
    PlayerRepeatToggled event,
    Emitter<PlayerState> emit,
  ) async {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    await _player.setLoopMode(switch (next) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    });
    emit(state.copyWith(repeatMode: next));
  }

  Future<void> _onSpeedChanged(
    PlayerSpeedChanged event,
    Emitter<PlayerState> emit,
  ) async {
    await _player.setSpeed(event.speed);
    emit(state.copyWith(speed: event.speed));
  }

  void _onQueueReordered(
    PlayerQueueReordered event,
    Emitter<PlayerState> emit,
  ) {
    final newQueue = List<SongModel>.from(state.queue);
    final item = newQueue.removeAt(event.oldIndex);
    newQueue.insert(event.newIndex, item);
    emit(state.copyWith(queue: newQueue));
  }

  void _onSongRemoved(
    PlayerSongRemovedFromQueue event,
    Emitter<PlayerState> emit,
  ) {
    if (event.index == state.currentIndex) return; // Can't remove current
    final newQueue = List<SongModel>.from(state.queue)
      ..removeAt(event.index);
    emit(state.copyWith(queue: newQueue));
  }

  Future<void> _onFavoriteToggled(
    PlayerFavoriteToggled event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.currentSong == null) return;
    final result = await _repository.toggleFavorite(state.currentSong!.id);
    result.fold(
      (f) => AppLogger.warning(f.message, tag: _tag),
      (updated) => emit(state.copyWith(currentSong: updated)),
    );
  }

  void _onPositionUpdated(
    _PlayerPositionUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(position: event.position));
  }

  void _onStateUpdated(
    _PlayerStateUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(
      isPlaying: event.isPlaying,
      duration: event.duration,
    ));
  }
}
