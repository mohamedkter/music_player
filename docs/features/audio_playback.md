# 🎵 Audio Playback

## المكتبات المستخدمة

- **`just_audio`** — محرك التشغيل
- **`audio_service`** — التشغيل في الخلفية + إشعار التحكم

---

## الإعداد الأساسي

### 1. AndroidManifest.xml

```xml
<manifest>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

  <application>
    <service
      android:name="com.ryanheise.audioservice.AudioServiceFragmentActivity"
      android:exported="true"
      tools:node="merge">
      <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON"/>
      </intent-filter>
    </service>

    <receiver
      android:name="androidx.media.session.MediaButtonReceiver"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON"/>
      </intent-filter>
    </receiver>
  </application>
</manifest>
```

### 2. AudioHandler

```dart
class MusicHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  MusicHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    play();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: const {
        ProcessingState.idle:     AudioProcessingState.idle,
        ProcessingState.loading:  AudioProcessingState.loading,
        ProcessingState.buffering:AudioProcessingState.buffering,
        ProcessingState.ready:    AudioProcessingState.ready,
        ProcessingState.completed:AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
```

### 3. تهيئة الـ AudioService في main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: () => MusicHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## تشغيل Queue كاملة

```dart
Future<void> playFromSongs(List<Song> songs, int startIndex) async {
  final audioSource = ConcatenatingAudioSource(
    children: songs.map((song) {
      return AudioSource.uri(
        Uri.file(song.data),
        tag: MediaItem(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: song.coverPath != null
              ? Uri.file(song.coverPath!)
              : null,
          duration: Duration(milliseconds: song.duration),
        ),
      );
    }).toList(),
  );

  await _player.setAudioSource(audioSource, initialIndex: startIndex);
  await _player.play();
}
```

---

## Shuffle & Repeat

```dart
// Shuffle
await _player.setShuffleModeEnabled(true);

// Repeat One
await _player.setLoopMode(LoopMode.one);

// Repeat All
await _player.setLoopMode(LoopMode.all);

// No Repeat
await _player.setLoopMode(LoopMode.off);
```

---

## سرعة التشغيل

```dart
await _player.setSpeed(1.5); // 0.5 → 2.0
```

---

## Gapless Playback

`just_audio` يدعم Gapless تلقائياً مع `ConcatenatingAudioSource`.
