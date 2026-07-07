# 📦 الباكدجز المقترحة

## الباكدجز الأساسية

| الباكدج | الإصدار | الغرض |
|---------|---------|--------|
| `just_audio` | ^0.9.x | محرك تشغيل الصوت الأساسي |
| `audio_service` | ^0.18.x | تشغيل خلفي + إشعار التحكم + Lock Screen |
| `on_audio_query` | ^2.9.x | قراءة مكتبة الموسيقى من MediaStore |
| `permission_handler` | ^11.x | طلب صلاحيات Storage |
| `isar` | ^3.x | قاعدة بيانات محلية سريعة |
| `isar_flutter_libs` | ^3.x | مكتبات Isar لـ Flutter |
| `riverpod` | ^2.x | إدارة الحالة |
| `flutter_riverpod` | ^2.x | تكامل Riverpod مع Flutter |

---

## الواجهة والتصميم

| الباكدج | الإصدار | الغرض |
|---------|---------|--------|
| `palette_generator` | ^0.3.x | استخراج الألوان من صورة الألبوم (Dynamic Color) |
| `cached_network_image` | ^3.x | تخزين مؤقت للصور |
| `blur` | ^3.x | تأثير Blur للخلفية |
| `animations` | ^2.x | انيميشن انتقال بين الشاشات |
| `sliding_up_panel` | ^2.x | Mini Player يرتفع لـ Now Playing |

---

## المرافق

| الباكدج | الإصدار | الغرض |
|---------|---------|--------|
| `shared_preferences` | ^2.x | حفظ الإعدادات (Theme, Accent Color...) |
| `path_provider` | ^2.x | الوصول لمسارات الجهاز |
| `rxdart` | ^0.27.x | Streams متقدمة للحالة |
| `equatable` | ^2.x | مقارنة الـ Models |

---

## الـ Equalizer

| الباكدج | الإصدار | الغرض |
|---------|---------|--------|
| `just_audio` (AndroidLoudnessEnhancer) | مدمج | Equalizer بسيط |
| `equalizer_flutter` | ^1.x | Equalizer نظام Android المدمج |

---

## Sleep Timer

يُنفَّذ داخلياً بـ `dart:async` دون باكدج خارجي:
```dart
Timer sleepTimer = Timer(duration, () => audioService.stop());
```

---

## اضافة الباكدجز لـ pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Audio
  just_audio: ^0.9.40
  audio_service: ^0.18.15
  on_audio_query: ^2.9.0

  # Permissions
  permission_handler: ^11.3.1

  # Database
  isar: ^3.1.8
  isar_flutter_libs: ^3.1.8
    platforms:
      android:
      ios:

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # UI
  palette_generator: ^0.3.3+3
  cached_network_image: ^3.3.1
  animations: ^2.0.11

  # Utils
  shared_preferences: ^2.3.2
  path_provider: ^2.1.4
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  isar_generator: ^3.1.8
  build_runner: ^2.4.12
  riverpod_generator: ^2.4.3
```

---

## ملاحظات

- `on_audio_query` يتيح قراءة البيانات من **MediaStore** مباشرة دون فحص يدوي للملفات
- `audio_service` يتطلب إعداداً خاصاً في `AndroidManifest.xml`
- `isar` يحتاج `build_runner` لتوليد الكود
