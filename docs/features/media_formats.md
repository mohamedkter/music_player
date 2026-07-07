# 🎵 صيغ الصوت المدعومة

## الصيغ

| الصيغة | الامتداد | الدعم في Android | الملاحظات |
|--------|----------|-----------------|----------|
| MP3    | `.mp3`   | ✅ مدمج          | الأكثر شيوعاً |
| FLAC   | `.flac`  | ✅ مدمج (API 16+) | جودة بدون فقدان |
| WAV    | `.wav`   | ✅ مدمج          | ملفات كبيرة الحجم |
| AAC    | `.aac`, `.m4a` | ✅ مدمج | متوافق مع Apple |
| OGG    | `.ogg`   | ✅ مدمج          | مفتوح المصدر |
| M4A    | `.m4a`   | ✅ مدمج          | iTunes / Apple Music |
| OPUS   | `.opus`  | ✅ (API 21+)     | مضغوط وعالي الجودة |
| WMA    | `.wma`   | ❌ غير مدعوم     | Microsoft format |

---

## `just_audio` والصيغ

`just_audio` يستخدم مشغّل الصوت المدمج في Android (ExoPlayer)، لذلك يدعم جميع الصيغ التي يدعمها Android.

### الصيغ عبر ExoPlayer

```
ExoPlayer (just_audio)
├── MP3    ✅
├── FLAC   ✅
├── WAV    ✅  
├── AAC    ✅
├── OGG    ✅
├── M4A    ✅
├── OPUS   ✅
└── WMA    ❌ (يحتاج extension خاص)
```

---

## فلترة الصيغ في `on_audio_query`

```dart
// الصيغ المدعومة للفلترة
final supportedFormats = ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a', '.opus'];

// أو استخدم AudiosAudioQuery مع filePath filter
final songs = await OnAudioQuery().querySongs(
  sortType: SongSortType.TITLE,
  orderType: OrderType.ASC_OR_SMALLER,
  uriType: UriType.EXTERNAL,
  ignoreCase: true,
);

// فلترة بعد الاستعلام
final filteredSongs = songs.where((song) {
  final ext = song.fileExtension?.toLowerCase() ?? '';
  return supportedFormats.contains('.$ext');
}).toList();
```

---

## بيانات ID3 Tags

البيانات المستخرجة من كل ملف:

| البيانات | الحقل | الملاحظة |
|----------|-------|----------|
| اسم الأغنية | `title` | |
| الفنان | `artist` | |
| الألبوم | `album` | |
| رقم الأغنية في الألبوم | `track` | |
| السنة | `year` | |
| النوع | `genre` | |
| صورة الغلاف | `artwork` | |
| كلمات الأغنية | `lyrics` (USLT) | من ID3 مباشرة |
| المدة | `duration` | مليثانية |
| معدل البيت | `bitrate` | kbps |

```dart
// استخراج صورة الألبوم
final artwork = await OnAudioQuery().queryArtwork(
  song.id,
  ArtworkType.AUDIO,
  quality: 100,
  size: 500,
);
```
