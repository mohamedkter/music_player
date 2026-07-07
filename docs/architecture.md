# 🏗️ معمارية المشروع

## نمط المعمارية المقترح: Feature-First + Clean Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart                  ← MaterialApp الرئيسي
│   ├── routes.dart               ← تعريف المسارات
│   └── theme/
│       ├── app_theme.dart
│       ├── dark_theme.dart
│       └── light_theme.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart    ← ثوابت عامة (مدة قصيرة، إلخ)
│   │   └── supported_formats.dart
│   ├── utils/
│   │   ├── duration_formatter.dart
│   │   ├── file_utils.dart
│   │   └── color_extractor.dart  ← استخراج لون من صورة الألبوم
│   ├── services/
│   │   ├── audio_service.dart    ← just_audio + audio_service
│   │   ├── media_scanner.dart    ← فحص ملفات الجهاز
│   │   └── notification_service.dart
│   └── widgets/
│       ├── mini_player.dart
│       └── app_bottom_nav.dart
│
├── data/
│   ├── models/
│   │   ├── song.dart
│   │   ├── artist.dart
│   │   ├── album.dart
│   │   ├── playlist.dart
│   │   └── folder.dart
│   ├── repositories/
│   │   ├── song_repository.dart
│   │   ├── playlist_repository.dart
│   │   └── settings_repository.dart
│   └── local/
│       ├── database.dart         ← Isar أو Hive أو sqflite
│       └── preferences.dart     ← shared_preferences
│
└── features/
    ├── home/
    │   ├── home_screen.dart
    │   └── home_controller.dart
    ├── songs/
    │   ├── songs_screen.dart
    │   └── songs_controller.dart
    ├── artists/
    │   ├── artists_screen.dart
    │   ├── artist_detail_screen.dart
    │   └── artists_controller.dart
    ├── albums/
    │   ├── albums_screen.dart
    │   ├── album_detail_screen.dart
    │   └── albums_controller.dart
    ├── folders/
    │   ├── folders_screen.dart
    │   └── folders_controller.dart
    ├── playlists/
    │   ├── playlists_screen.dart
    │   ├── playlist_detail_screen.dart
    │   └── playlists_controller.dart
    ├── now_playing/
    │   ├── now_playing_screen.dart
    │   ├── queue_screen.dart
    │   └── now_playing_controller.dart
    ├── lyrics/
    │   ├── lyrics_screen.dart
    │   └── lyrics_controller.dart
    ├── search/
    │   ├── search_screen.dart
    │   └── search_controller.dart
    └── settings/
        ├── settings_screen.dart
        └── settings_controller.dart
```

---

## 🔄 إدارة الحالة

**المقترح: Riverpod**

- خفيف الوزن ومدعوم جيداً مع Flutter
- مناسب لإدارة حالة المشغل (`PlayerState`) عبر الشاشات
- يدعم `AsyncNotifier` لعمليات قراءة الملفات

```
PlayerNotifier (Riverpod)
  ├── currentSong
  ├── isPlaying
  ├── position / duration
  ├── queue
  ├── shuffleMode
  └── repeatMode
```

---

## 🧱 طبقات المشروع

```
UI Layer (Screens + Widgets)
        ↕
Controller Layer (Riverpod Notifiers)
        ↕
Repository Layer (بيانات مجردة)
        ↕
Data Layer (Local DB + MediaStore)
```

---

## 📦 قاعدة البيانات المحلية

**Isar Database** (الأسرع والأخف)

الجداول:
- `SongEntity`
- `ArtistEntity`
- `AlbumEntity`
- `PlaylistEntity`
- `PlaylistSongEntity`
- `RecentlyPlayedEntity`

---

## 🎵 طبقة الصوت

```
AudioService (background isolate)
    └── just_audio (player engine)
         ├── ConcatenatingAudioSource (Queue)
         ├── LoopMode (Repeat)
         └── shuffleModeEnabled (Shuffle)
```

---

## 🔔 الإشعارات وشاشة القفل

يتم التعامل معها تلقائياً عبر:
- `audio_service` — يوفر MediaNotification
- `just_audio` — يتكامل مع audio_service
