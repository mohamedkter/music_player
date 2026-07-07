# 🗄️ قاعدة البيانات المحلية

## المكتبة المختارة: Isar

**لماذا Isar؟**
- الأسرع في Flutter (مبني بـ Rust)
- يدعم الاستعلامات المعقدة
- تزامن مع الـ UI عبر `watchLazy()`
- لا يحتاج ORM معقد

---

## الإعداد

### pubspec.yaml
```yaml
dependencies:
  isar: ^3.1.8
  isar_flutter_libs: ^3.1.8
    platforms:
      android:
      ios:

dev_dependencies:
  isar_generator: ^3.1.8
  build_runner: ^2.4.12
```

### توليد الكود
```bash
dart run build_runner build
```

---

## تهيئة قاعدة البيانات

```dart
class DatabaseService {
  static Isar? _isar;

  static Future<Isar> get instance async {
    _isar ??= await _init();
    return _isar!;
  }

  static Future<Isar> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        SongSchema,
        ArtistSchema,
        AlbumSchema,
        PlaylistSchema,
        PlaylistSongSchema,
        RecentlyPlayedSchema,
      ],
      directory: dir.path,
    );
  }
}
```

---

## عمليات الأغاني الشائعة

```dart
class SongRepository {
  final Isar _isar;

  // جلب جميع الأغاني
  Future<List<Song>> getAllSongs({
    SongSortType sort = SongSortType.title,
  }) async {
    return _isar.songs.where().findAll();
  }

  // البحث
  Future<List<Song>> search(String query) async {
    return _isar.songs
        .filter()
        .titleContains(query, caseSensitive: false)
        .or()
        .artistContains(query, caseSensitive: false)
        .or()
        .albumContains(query, caseSensitive: false)
        .findAll();
  }

  // تحديث عداد التشغيل
  Future<void> incrementPlayCount(int songId) async {
    await _isar.writeTxn(() async {
      final song = await _isar.songs.get(songId);
      if (song != null) {
        song.playCount++;
        song.lastPlayed = DateTime.now().millisecondsSinceEpoch;
        await _isar.songs.put(song);
      }
    });
  }

  // تبديل المفضلة
  Future<void> toggleFavorite(int songId) async {
    await _isar.writeTxn(() async {
      final song = await _isar.songs.get(songId);
      if (song != null) {
        song.isFavorite = !song.isFavorite;
        await _isar.songs.put(song);
      }
    });
  }

  // الأكثر تشغيلاً
  Future<List<Song>> getMostPlayed({int limit = 10}) async {
    return _isar.songs
        .filter()
        .playCountGreaterThan(0)
        .sortByPlayCountDesc()
        .limit(limit)
        .findAll();
  }

  // المضافة حديثاً
  Future<List<Song>> getRecentlyAdded({int limit = 20}) async {
    return _isar.songs
        .where()
        .sortByDateAddedDesc()
        .limit(limit)
        .findAll();
  }

  // مراقبة التغييرات (Reactive)
  Stream<List<Song>> watchFavorites() {
    return _isar.songs
        .filter()
        .isFavoriteEqualTo(true)
        .watch(fireImmediately: true);
  }
}
```

---

## فحص وإضافة المكتبة الموسيقية

```dart
class MediaScannerService {
  final Isar _isar;
  final OnAudioQuery _query = OnAudioQuery();

  Future<void> scanLibrary() async {
    // جلب الأغاني من MediaStore
    final deviceSongs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      uriType: UriType.EXTERNAL,
    );

    // تصفية الملفات القصيرة
    final minDuration = await settingsRepo.getMinDuration(); // 30 ثانية
    final filtered = deviceSongs.where(
      (s) => (s.duration ?? 0) >= minDuration * 1000,
    ).toList();

    // مزامنة مع قاعدة البيانات
    await _isar.writeTxn(() async {
      for (final deviceSong in filtered) {
        final existing = await _isar.songs
            .filter()
            .dataEqualTo(deviceSong.data ?? '')
            .findFirst();

        if (existing == null) {
          // أغنية جديدة
          await _isar.songs.put(deviceSong.toSong());
        }
      }

      // حذف الأغاني المحذوفة من الجهاز
      final devicePaths = filtered.map((s) => s.data ?? '').toSet();
      final dbSongs = await _isar.songs.where().findAll();
      for (final dbSong in dbSongs) {
        if (!devicePaths.contains(dbSong.data)) {
          await _isar.songs.delete(dbSong.id);
        }
      }
    });
  }
}
```

---

## مخطط العلاقات

```
Song ──────────────── RecentlyPlayed
 │                         │
 │ (many-to-many)          │ songId
 │                         │
Playlist ──── PlaylistSong ┘
                    │
                    │ playlistId, songId, order
```
