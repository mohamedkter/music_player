import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song_model.dart';
import '../utils/logger.dart';

/// Initializes the global [AudioHandler] instance.
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
}

/// Custom [AudioHandler] that bridges `just_audio` playback with `audio_service` to support
/// system-level media controls, background playback, and system lock screen metadata.
class MusicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late ConcatenatingAudioSource _playlist;
  static const _tag = 'MusicAudioHandler';

  MusicAudioHandler() {
    _init();
  }

  // Expose player properties/streams for convenience in Bloc
  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  void _init() {
    // 1. Forward playback state events to the audio_service platform channel
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // 2. Sync the active media item when just_audio transitions to another index
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // 3. Stop player when queue finishes
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
      }
    });
  }

  /// Sets the queue and maps our app's [SongModel] to [MediaItem] objects.
  Future<void> setQueueItems(List<SongModel> songs) async {
    final mediaItems = songs.map((s) => MediaItem(
      id: s.id.toString(),
      album: s.album,
      title: s.title,
      artist: s.artist,
      duration: Duration(milliseconds: s.duration),
      artUri: s.coverPath != null && s.coverPath!.isNotEmpty
          ? Uri.file(s.coverPath!)
          : null,
      extras: {
        'data': s.data,
      },
    )).toList();

    queue.add(mediaItems);

    _playlist = ConcatenatingAudioSource(
      children: mediaItems.map((item) => AudioSource.uri(
        Uri.file(item.extras!['data'] as String),
        tag: item,
      )).toList(),
    );

    await _player.setAudioSource(_playlist);
  }

  /// Plays a specific song from the current/new queue.
  Future<void> playSong(SongModel song, List<SongModel> songsQueue) async {
    try {
      final isNewQueue = queue.value.length != songsQueue.length || 
          queue.value.isEmpty || 
          queue.value.first.id != songsQueue.first.id.toString();

      if (isNewQueue) {
        await setQueueItems(songsQueue);
      }

      final index = songsQueue.indexWhere((s) => s.id == song.id);
      if (index >= 0) {
        await _player.seek(Duration.zero, index: index);
        await play();
      }
    } catch (e, st) {
      AppLogger.error('playSong failed', tag: _tag, error: e, stackTrace: st);
    }
  }

  /// Handles queue reordering dynamically without restarting playback.
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      await _playlist.move(oldIndex, newIndex);
      final list = List<MediaItem>.from(queue.value);
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      queue.add(list);
    } catch (e, st) {
      AppLogger.error('moveQueueItem failed', tag: _tag, error: e, stackTrace: st);
    }
  }

  /// Handles queue removal dynamically.
  Future<void> removeQueueItemAt(int index) async {
    try {
      await _playlist.removeAt(index);
      final list = List<MediaItem>.from(queue.value)..removeAt(index);
      queue.add(list);
    } catch (e, st) {
      AppLogger.error('removeQueueItemAt failed', tag: _tag, error: e, stackTrace: st);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    switch (shuffleMode) {
      case AudioServiceShuffleMode.none:
        await _player.setShuffleModeEnabled(false);
      case AudioServiceShuffleMode.all:
      case AudioServiceShuffleMode.group:
        await _player.setShuffleModeEnabled(true);
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Helper to convert just_audio player states into audio_service states.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
