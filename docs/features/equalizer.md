# 🎚️ Equalizer

## الخيارات المتاحة

### الخيار 1: Equalizer النظام المدمج (Android)

يفتح Equalizer الرسمي لنظام Android مباشرة.

```yaml
equalizer_flutter: ^1.0.2
```

```dart
import 'package:equalizer_flutter/equalizer_flutter.dart';

// فتح Equalizer النظام
EqualizerFlutter.open(audioSessionId);
```

مميزات:
- ✅ لا حاجة لتصميم واجهة
- ✅ يعمل على مستوى النظام (يؤثر على كل الصوت)
- ❌ تصميمه يعتمد على الجهاز/الشركة المصنعة

---

### الخيار 2: Equalizer مخصص داخل التطبيق

```dart
// just_audio يوفر AndroidLoudnessEnhancer
final _loudnessEnhancer = AndroidLoudnessEnhancer();
await _player.setAndroidAudioEffects([_loudnessEnhancer]);
await _loudnessEnhancer.setEnabled(true);
await _loudnessEnhancer.setTargetGain(0.5); // 0.0 → 1.0
```

---

## واجهة Equalizer المخصصة

```
┌─────────────────────────────────────┐
│  🎚 Equalizer              [إعادة]  │
├─────────────────────────────────────┤
│                                     │
│  اختر إعداداً مسبقاً:              │
│  [Normal] [Rock] [Pop] [Jazz] [Bass]│
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  60Hz  230Hz  910Hz  4kHz  14kHz   │
│   │      │      │      │      │    │
│   ▲      ▲             ▲           │  ← Sliders رأسية
│   │      │      │      │      │    │
│  [─]    [─]    [─]    [─]    [─]   │  ← قيمة 0 dB
│   │      │      │      │      │    │
│   ▼             ▼             ▼    │
│                                     │
│  -12dB              +12dB          │
│                                     │
│  Bass Boost: ●────────── 50%       │
│  Virtualizer: ●────────── 30%      │
│                                     │
└─────────────────────────────────────┘
```

---

## الإعدادات المسبقة (Presets)

| الإعداد | 60Hz | 230Hz | 910Hz | 4kHz | 14kHz |
|---------|------|-------|-------|------|-------|
| Normal  | 0    | 0     | 0     | 0    | 0     |
| Rock    | +4   | +2    | -2    | +2   | +4    |
| Pop     | -1   | +2    | +4    | +2   | -1    |
| Jazz    | +3   | +2    | 0     | +2   | +3    |
| Classical | 0  | 0     | 0     | -2   | -4    |
| Bass    | +6   | +4    | 0     | -1   | -1    |

---

## حفظ إعدادات Equalizer

```dart
await prefs.setStringList('eq_bands', bands.map((b) => b.toString()).toList());
await prefs.setString('eq_preset', presetName);
await prefs.setInt('bass_boost', bassBoostValue);
```
