# 📊 نماذج البيانات (Models)

## Song

```dart
@Collection()
class Song {
  Id id = Isar.autoIncrement;

  late String title;          // اسم الأغنية
  late String artist;         // اسم الفنان
  late String album;          // اسم الألبوم
  late String data;           // المسار الكامل للملف
  late int duration;          // المدة بالمليثواني
  late int size;              // الحجم بالبايت
  late int dateAdded;         // تاريخ الإضافة (timestamp)
  late int dateModified;      // تاريخ التعديل
  String? genre;              // النوع الموسيقي
  int? track;                 // رقم الأغنية في الألبوم
  int? year;                  // سنة الإصدار
  String? coverPath;          // مسار صورة الغلاف
  int? bitrate;               // معدل البيت

  // إحصائيات
  int playCount = 0;          // عدد مرات التشغيل
  int lastPlayed = 0;         // آخر تشغيل (timestamp)
  bool isFavorite = false;    // مفضلة

  // Computed
  String get fileExtension => data.split('.').last.toLowerCase();
  String get folderName => data.substring(0, data.lastIndexOf('/')).split('/').last;
  String get folderPath => data.substring(0, data.lastIndexOf('/'));
  Duration get durationObj => Duration(milliseconds: duration);
}
```

---

## Artist

```dart
@Collection()
class Artist {
  Id id = Isar.autoIncrement;

  late String name;
  late int numberOfTracks;
  late int numberOfAlbums;
  String? coverPath;          // من أول ألبوم
}
```

---

## Album

```dart
@Collection()
class Album {
  Id id = Isar.autoIncrement;

  late String title;
  late String artist;
  late int numberOfSongs;
  int? year;
  String? coverPath;
}
```

---

## Playlist

```dart
@Collection()
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;
  String? coverPath;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool isDefault = false;     // Favorites / Recently Played / Most Played
  String? defaultType;        // 'favorites' | 'recently_played' | 'most_played'
}
```

---

## PlaylistSong (علاقة رابطة)

```dart
@Collection()
class PlaylistSong {
  Id id = Isar.autoIncrement;

  late int playlistId;
  late int songId;
  late int order;            // ترتيب الأغنية في الـ Playlist
  late DateTime addedAt;
}
```

---

## RecentlyPlayed

```dart
@Collection()
class RecentlyPlayed {
  Id id = Isar.autoIncrement;

  late int songId;
  late DateTime playedAt;
}
```

---

## Settings (بـ shared_preferences)

| المفتاح | النوع | الافتراضي | الوصف |
|---------|-------|-----------|-------|
| `theme_mode` | int | 2 (system) | 0=light, 1=dark, 2=system |
| `accent_color` | int | 0xFF7C4DFF | اللون الرئيسي |
| `dynamic_color` | bool | true | استخراج اللون من الألبوم |
| `ignore_short_audio` | bool | true | تجاهل الملفات القصيرة |
| `min_audio_duration` | int | 30 | الحد الأدنى للمدة (ثانية) |
| `excluded_folders` | List\<String\> | [] | المجلدات المستثناة |
| `equalizer_preset` | String | 'Normal' | الإعداد المسبق |
| `last_song_id` | int | -1 | آخر أغنية تم تشغيلها |
| `last_position` | int | 0 | آخر موضع تشغيل (ms) |
| `shuffle_enabled` | bool | false | حالة Shuffle |
| `repeat_mode` | int | 0 | 0=off, 1=one, 2=all |
| `playback_speed` | double | 1.0 | سرعة التشغيل |
