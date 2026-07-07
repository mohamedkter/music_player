import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart' show Color, FileImage;

import '../../../data/models/song_model.dart';
import '../../../data/repositories/song_repository.dart';
import '../../../data/datasources/preferences_datasource.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/audio_handler.dart';

part 'player_event.dart';
part 'player_state.dart';

/// Singleton-style BLoC — provided at the root so it survives navigation.
/// Manages playback by delegating commands to the background [AudioHandler].
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc(
    this._repository,
    this._prefs,
    this._audioHandler,
  ) : super(const PlayerState()) {
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
    on<PlayerSleepTimerStarted>(_onSleepTimerStarted);
    on<PlayerSleepTimerCancelled>(_onSleepTimerCancelled);
    on<PlayerQueueCleared>(_onQueueCleared);
    on<PlayerInitializeRequested>(_onInitialize);
    on<PlayerDancerChanged>(_onDancerChanged);
    on<_PlayerPositionUpdated>(_onPositionUpdated);
    on<_PlayerStateUpdated>(_onStateUpdated);
    on<_PlayerSleepTimerTicked>(_onSleepTimerTicked);
    on<_PlayerMediaItemChanged>(_onMediaItemChanged);

    _subscribeToAudioHandler();
    add(PlayerInitializeRequested());
  }

  final SongRepository _repository;
  final PreferencesDataSource _prefs;
  final MusicAudioHandler _audioHandler;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<MediaItem?>? _mediaSub;
  Timer? _sleepTimer;

  static const _tag = 'PlayerBloc';

  // ── Lifecycle & Initialization ─────────────────────────────────────────────

  void _subscribeToAudioHandler() {
    _posSub = _audioHandler.positionStream.listen(
      (pos) => add(_PlayerPositionUpdated(pos)),
      onError: (e) => AppLogger.error('Position stream error', tag: _tag, error: e),
    );

    _stateSub = _audioHandler.playbackState.listen(
      (pState) => add(_PlayerStateUpdated(
        isPlaying: pState.playing,
        duration: _audioHandler.mediaItem.value?.duration ?? Duration.zero,
      )),
      onError: (e) => AppLogger.error('PlaybackState stream error', tag: _tag, error: e),
    );

    _mediaSub = _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        add(_PlayerMediaItemChanged(item));
      }
    });
  }

  Future<void> _onInitialize(
    PlayerInitializeRequested event,
    Emitter<PlayerState> emit,
  ) async {
    await _restorePersistedState(emit);
  }

  Future<void> _restorePersistedState(Emitter<PlayerState> emit) async {
    try {
      final speed = _prefs.getPlaybackSpeed();
      final shuffle = _prefs.getShuffleEnabled();
      final repeat = RepeatMode.values[_prefs.getRepeatMode().clamp(0, 2)];

      await _audioHandler.setSpeed(speed);
      await _audioHandler.setShuffleMode(shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
      await _audioHandler.setRepeatMode(switch (repeat) {
        RepeatMode.off => AudioServiceRepeatMode.none,
        RepeatMode.one => AudioServiceRepeatMode.one,
        RepeatMode.all => AudioServiceRepeatMode.all,
      });

      final dancer = _prefs.getSelectedDancer();

      emit(state.copyWith(
        speed: speed,
        shuffleEnabled: shuffle,
        repeatMode: repeat,
        selectedDancer: dancer,
      ));

      // Restore last active song and queue if available
      final lastSongId = _prefs.getLastSongId();
      if (lastSongId != -1) {
        final songsResult = await _repository.getAllSongs();
        await songsResult.fold(
          (failure) async => AppLogger.warning('Failed to load songs for persistence', tag: _tag),
          (songs) async {
            final lastSongIndex = songs.indexWhere((s) => s.id == lastSongId);
            if (lastSongIndex >= 0) {
              final lastSong = songs[lastSongIndex];
              await _audioHandler.setQueueItems(songs);
              
              final lastPos = Duration(milliseconds: _prefs.getLastPosition());
              await _audioHandler.player.seek(lastPos, index: lastSongIndex);

              final colors = await _extractPalette(lastSong.coverPath);

              emit(state.copyWith(
                currentSong: lastSong,
                queue: songs,
                currentIndex: lastSongIndex,
                position: lastPos,
                primaryColor: colors.$1,
                secondaryColor: colors.$2,
              ));
            }
          },
        );
      }
    } catch (e, st) {
      AppLogger.error('Failed to restore persisted player state', tag: _tag, error: e, stackTrace: st);
    }
  }

  @override
  Future<void> close() async {
    _sleepTimer?.cancel();
    await _posSub?.cancel();
    await _stateSub?.cancel();
    await _mediaSub?.cancel();
    super.close();
  }

  // ── Event Handlers ─────────────────────────────────────────────────────────

  Future<void> _onSongRequested(
    PlayerSongRequested event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final startIndex = event.queue.indexWhere((s) => s.id == event.song.id);
      final idx = startIndex < 0 ? 0 : startIndex;

      // Extract colors before playing for smooth transition
      final colors = await _extractPalette(event.song.coverPath);

      emit(state.copyWith(
        currentSong: event.song,
        queue: event.queue,
        currentIndex: idx,
        isPlaying: true,
        position: Duration.zero,
        primaryColor: colors.$1,
        secondaryColor: colors.$2,
      ));

      await _audioHandler.playSong(event.song, event.queue);
      await _repository.recordPlay(event.song.id);
      
      emit(state.copyWith(isLoading: false));
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
    if (state.isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> _onNext(
    PlayerSkipToNext event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.skipToNext();
  }

  Future<void> _onPrevious(
    PlayerSkipToPrevious event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> _onSeek(
    PlayerSeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.seek(event.position);
  }

  Future<void> _onShuffle(
    PlayerShuffleToggled event,
    Emitter<PlayerState> emit,
  ) async {
    final newVal = !state.shuffleEnabled;
    await _audioHandler.setShuffleMode(newVal ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    await _prefs.saveShuffleEnabled(newVal);
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
    await _audioHandler.setRepeatMode(switch (next) {
      RepeatMode.off => AudioServiceRepeatMode.none,
      RepeatMode.all => AudioServiceRepeatMode.all,
      RepeatMode.one => AudioServiceRepeatMode.one,
    });
    await _prefs.saveRepeatMode(next.index);
    emit(state.copyWith(repeatMode: next));
  }

  Future<void> _onSpeedChanged(
    PlayerSpeedChanged event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.setSpeed(event.speed);
    await _prefs.savePlaybackSpeed(event.speed);
    emit(state.copyWith(speed: event.speed));
  }

  Future<void> _onQueueReordered(
    PlayerQueueReordered event,
    Emitter<PlayerState> emit,
  ) async {
    final newQueue = List<SongModel>.from(state.queue);
    final item = newQueue.removeAt(event.oldIndex);
    newQueue.insert(event.newIndex, item);

    final currentIdx = state.currentIndex;
    int newIdx = currentIdx;

    if (currentIdx == event.oldIndex) {
      newIdx = event.newIndex;
    } else if (currentIdx > event.oldIndex && currentIdx <= event.newIndex) {
      newIdx = currentIdx - 1;
    } else if (currentIdx < event.oldIndex && currentIdx >= event.newIndex) {
      newIdx = currentIdx + 1;
    }

    emit(state.copyWith(queue: newQueue, currentIndex: newIdx));
    await _audioHandler.moveQueueItem(event.oldIndex, event.newIndex);
  }

  Future<void> _onSongRemoved(
    PlayerSongRemovedFromQueue event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.index == state.currentIndex) return; // Cannot remove active song
    
    final newQueue = List<SongModel>.from(state.queue)..removeAt(event.index);
    final currentIdx = state.currentIndex;
    final newIdx = event.index < currentIdx ? currentIdx - 1 : currentIdx;

    emit(state.copyWith(queue: newQueue, currentIndex: newIdx));
    await _audioHandler.removeQueueItemAt(event.index);
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

  void _onSleepTimerStarted(
    PlayerSleepTimerStarted event,
    Emitter<PlayerState> emit,
  ) {
    _sleepTimer?.cancel();
    emit(state.copyWith(sleepTimerRemaining: event.duration));

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.sleepTimerRemaining;
      if (remaining == null || remaining.inSeconds <= 1) {
        add(PlayerSleepTimerCancelled());
        if (state.isPlaying) {
          add(PlayerTogglePlayPause());
        }
      } else {
        add(_PlayerSleepTimerTicked(remaining - const Duration(seconds: 1)));
      }
    });
  }

  void _onSleepTimerCancelled(
    PlayerSleepTimerCancelled event,
    Emitter<PlayerState> emit,
  ) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    emit(state.copyWithClearedSleepTimer());
  }

  void _onPositionUpdated(
    _PlayerPositionUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(position: event.position));
    
    // Debounce state saving — write to shared_preferences every 5 seconds
    if (event.position.inSeconds % 5 == 0) {
      _prefs.saveLastPosition(event.position.inMilliseconds);
    }
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

  void _onSleepTimerTicked(
    _PlayerSleepTimerTicked event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(sleepTimerRemaining: event.remaining));
  }

  Future<void> _onMediaItemChanged(
    _PlayerMediaItemChanged event,
    Emitter<PlayerState> emit,
  ) async {
    final item = event.item;
    final id = int.tryParse(item.id);
    if (id != null) {
      final songIndex = state.queue.indexWhere((s) => s.id == id);
      final song = songIndex >= 0 ? state.queue[songIndex] : state.currentSong;
      if (song != null) {
        _prefs.saveLastSongId(song.id);
        final colors = await _extractPalette(song.coverPath);

        emit(state.copyWith(
          currentSong: song,
          currentIndex: songIndex >= 0 ? songIndex : state.currentIndex,
          primaryColor: colors.$1,
          secondaryColor: colors.$2,
        ));
      }
    }
  }

  Future<void> _onQueueCleared(
    PlayerQueueCleared event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.stop();
    emit(const PlayerState());
  }

  // ── Palette Generator Helper ───────────────────────────────────────────────

  Future<(Color?, Color?)> _extractPalette(String? coverPath) async {
    if (coverPath == null || coverPath.isEmpty) return (null, null);
    try {
      final file = File(coverPath);
      if (await file.exists()) {
        final palette = await PaletteGenerator.fromImageProvider(FileImage(file));
        final primary = palette.dominantColor?.color;
        final secondary = palette.darkMutedColor?.color ?? 
                          palette.darkVibrantColor?.color ?? 
                          palette.dominantColor?.color.withValues(alpha: 0.4);
        return (primary, secondary);
      }
    } catch (e) {
      AppLogger.warning('Failed to extract album art color palette: $e', tag: _tag);
    }
    return (null, null);
  }

  Future<void> _onDancerChanged(
    PlayerDancerChanged event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(selectedDancer: event.dancerPath));
    await _prefs.saveSelectedDancer(event.dancerPath);
  }
}
