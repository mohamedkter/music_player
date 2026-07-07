# 🎨 Dynamic Color

## الوصف

استخراج الألوان السائدة من صورة غلاف الألبوم وتطبيقها على واجهة Now Playing لتجربة مرئية فريدة لكل أغنية.

---

## المكتبة المستخدمة

```yaml
palette_generator: ^0.3.3+3
```

---

## الألوان المستخرجة

| اللون | الاستخدام |
|-------|-----------|
| `dominantColor` | خلفية الشاشة (gradient) |
| `vibrantColor` | أزرار التحكم + شريط التقدم |
| `mutedColor` | نص ثانوي |
| `darkVibrantColor` | خلفية داكنة |
| `lightVibrantColor` | خلفية فاتحة |

---

## التنفيذ

```dart
class DynamicColorService {
  static Future<AlbumColors> extractColors(String? imagePath) async {
    if (imagePath == null) return AlbumColors.fallback();

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(File(imagePath)),
        maximumColorCount: 20,
      );

      return AlbumColors(
        dominant:     palette.dominantColor?.color     ?? Colors.purple,
        vibrant:      palette.vibrantColor?.color      ?? Colors.purpleAccent,
        muted:        palette.mutedColor?.color        ?? Colors.grey,
        darkVibrant:  palette.darkVibrantColor?.color  ?? Colors.deepPurple,
      );
    } catch (_) {
      return AlbumColors.fallback();
    }
  }
}

class AlbumColors {
  final Color dominant;
  final Color vibrant;
  final Color muted;
  final Color darkVibrant;

  const AlbumColors({
    required this.dominant,
    required this.vibrant,
    required this.muted,
    required this.darkVibrant,
  });

  factory AlbumColors.fallback() => const AlbumColors(
    dominant:    Color(0xFF1A1A2E),
    vibrant:     Color(0xFF7C4DFF),
    muted:       Color(0xFF9E9E9E),
    darkVibrant: Color(0xFF311B92),
  );
}
```

---

## تطبيق اللون على Now Playing

```dart
// في Now Playing Screen
AnimatedContainer(
  duration: const Duration(milliseconds: 500),
  curve: Curves.easeInOut,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        albumColors.darkVibrant,
        Colors.black,
      ],
    ),
  ),
  child: NowPlayingContent(),
)
```

---

## التخزين المؤقت (Cache)

لتجنب إعادة الحساب في كل مرة، خزّن النتائج:

```dart
final Map<String, AlbumColors> _colorCache = {};

Future<AlbumColors> getColors(String albumId, String? coverPath) async {
  if (_colorCache.containsKey(albumId)) {
    return _colorCache[albumId]!;
  }
  final colors = await DynamicColorService.extractColors(coverPath);
  _colorCache[albumId] = colors;
  return colors;
}
```

---

## قراءة ألوان Material You (Android 12+)

```yaml
dynamic_color: ^1.7.0
```

```dart
DynamicColorBuilder(
  builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    // استخدم ألوان النظام إذا توفرت
    final colorScheme = darkDynamic ?? ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );
    return MaterialApp(theme: ThemeData(colorScheme: colorScheme));
  },
)
```
