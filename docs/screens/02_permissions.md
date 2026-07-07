# 2️⃣ شاشة الصلاحيات (Permissions)

## الوصف

تُعرض عند أول تشغيل للتطبيق أو إذا لم تُمنح صلاحية الوصول للتخزين.

---

## الصلاحيات المطلوبة

| الصلاحية | الأهمية | Android API |
|----------|---------|-------------|
| `READ_MEDIA_AUDIO` | **ضروري** — قراءة ملفات الصوت | API 33+ |
| `READ_EXTERNAL_STORAGE` | **ضروري** — للإصدارات الأقدم | API < 33 |
| `POST_NOTIFICATIONS` | اختياري — إشعار التحكم | API 33+ |
| `FOREGROUND_SERVICE` | **ضروري** — التشغيل الخلفي | كل الإصدارات |

---

## العناصر البصرية

```
┌─────────────────────────────┐
│                             │
│   🎵  (أيقونة كبيرة)        │
│                             │
│   نحتاج إذنك للوصول        │
│   إلى مكتبتك الموسيقية     │
│                             │
│  ┌─────────────────────┐   │
│  │ 🔊 ملفات الصوت      │   │
│  │ للاستماع لموسيقاك   │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 🔔 الإشعارات (اختياري)│  │
│  │ للتحكم من الشريط    │   │
│  └─────────────────────┘   │
│                             │
│  [ السماح بالوصول ]         │
│                             │
└─────────────────────────────┘
```

---

## المنطق

```dart
// التحقق من إصدار Android
if (Platform.isAndroid) {
  if (androidVersion >= 33) {
    await Permission.audio.request();
  } else {
    await Permission.storage.request();
  }
}
```

### الحالات الممكنة

| الحالة | الإجراء |
|--------|---------|
| ممنوحة | الانتقال للـ Home |
| مرفوضة | عرض رسالة توضيحية + زر المحاولة مجدداً |
| مرفوضة نهائياً (Don't ask again) | فتح إعدادات التطبيق |

---

## AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
