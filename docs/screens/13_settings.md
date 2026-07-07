# 1️⃣3️⃣ Settings Screen

## الوصف

إعدادات التطبيق الشاملة — المظهر، الصوت، المكتبة، وغيرها.

---

## التخطيط

```
┌─────────────────────────────────┐
│  ⚙️ الإعدادات                   │
├─────────────────────────────────┤
│                                 │
│  🎨 المظهر                      │
│  ├─ Theme                       │
│  │   ◉ داكن  ○ فاتح  ○ تلقائي  │
│  ├─ Accent Color                │
│  │   🔵 🟣 🟠 🔴 🟢 ⚫ [مخصص]   │
│  └─ Dynamic Color               │
│      (استخراج من صورة الألبوم)  │
│                                 │
│  ─────────────────────────────  │
│  🎵 الصوت                       │
│  ├─ Equalizer           [فتح]  │
│  ├─ جودة الصوت                  │
│  │   ◉ عالية  ○ متوسطة  ○ منخفضة│
│  └─ تطبيع الصوت (Gapless)  [☑] │
│                                 │
│  ─────────────────────────────  │
│  📚 المكتبة                     │
│  ├─ فحص الموسيقى        [فحص]  │
│  ├─ تجاهل الملفات القصيرة [☑]  │
│  │   أقل من:  [30 ثانية ▾]     │
│  ├─ المجلدات المستثناة   [تعديل]│
│  └─ فحص تلقائي عند الفتح  [☑]  │
│                                 │
│  ─────────────────────────────  │
│  ⏱ Sleep Timer          [ضبط]  │
│                                 │
│  ─────────────────────────────  │
│  ℹ عن التطبيق                   │
│  ├─ الإصدار: 1.0.0              │
│  ├─ التحقق من التحديثات         │
│  └─ سياسة الخصوصية             │
│                                 │
└─────────────────────────────────┘
```

---

## تفاصيل الإعدادات

### 🎨 Theme
| الخيار | الوصف |
|--------|-------|
| داكن | Dark Mode دائماً |
| فاتح | Light Mode دائماً |
| تلقائي | يتبع إعداد النظام |

### 🎨 Accent Color
- ألوان محددة مسبقاً (6-8 ألوان)
- أو Color Picker مخصص
- أو **Dynamic** (من صورة الألبوم)

### 🎵 Equalizer
يفتح Equalizer النظام أو Equalizer مخصص داخل التطبيق.

### 📚 تجاهل الملفات القصيرة
- عند التفعيل، يُستثنى من المكتبة أي ملف أقل من المدة المحددة
- الحد الافتراضي: 30 ثانية
- مفيد لاستثناء نغمات الإشعارات والرنين

### 📂 المجلدات المستثناة
```
مجلدات مستثناة:
- /storage/.../Ringtones
- /storage/.../Notifications
[ + إضافة مجلد ]
```

### 📚 فحص الموسيقى
- زر "فحص الآن" يعيد قراءة المكتبة كاملاً
- يُعرض شريط تقدم أثناء الفحص
- عدد الأغاني قبل وبعد

---

## حفظ الإعدادات

```dart
// باستخدام shared_preferences
class SettingsRepository {
  static const _themeKey = 'theme_mode';
  static const _accentColorKey = 'accent_color';
  static const _ignoreDurationKey = 'ignore_duration';
  static const _dynamicColorKey = 'dynamic_color';

  Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<ThemeMode> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    return ThemeMode.values[index];
  }
}
```

---

## عن التطبيق

```
┌─────────────────────────────────┐
│  🎵 Music Player                │
│  الإصدار 1.0.0                  │
│                                 │
│  مبني بـ Flutter 💙             │
│                                 │
│  [ سياسة الخصوصية ]            │
│  [ شروط الاستخدام ]             │
│  [ GitHub / المطور ]           │
└─────────────────────────────────┘
```
