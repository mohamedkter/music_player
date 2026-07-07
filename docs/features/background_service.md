# 🔔 Background Service & Notifications

## الوصف

تشغيل الموسيقى في الخلفية مع إشعار تحكم وعناصر تحكم من شاشة القفل.

---

## كيف يعمل

```
التطبيق (UI)
    │
    │  يتواصل مع
    ▼
AudioService (Foreground Service)
    │
    ├── just_audio (التشغيل الفعلي)
    ├── Media Session (شاشة القفل)
    └── Media Notification (شريط الإشعارات)
```

---

## إشعار التحكم (Media Notification)

يظهر تلقائياً في شريط الإشعارات ويحتوي على:

```
┌─────────────────────────────────────┐
│  🎵 Music Player                    │
│  ┌──────┐  اسم الأغنية             │
│  │صورة  │  الفنان                   │
│  └──────┘  ⏮  ⏸  ⏭              │
└─────────────────────────────────────┘
```

يتم التعامل معه تلقائياً عبر `audio_service`.

---

## عناصر تحكم شاشة القفل

`audio_service` يسجل `MediaSession` تلقائياً مما يتيح:
- عرض اسم الأغنية والفنان وصورة الألبوم
- أزرار تشغيل/إيقاف + تالي + سابق
- شريط التقدم

---

## الحالة عند إغلاق التطبيق

```dart
// في AudioServiceConfig
AndroidServiceConfig(
  androidStopForegroundOnPause: false,  // يبقى الـ Service نشطاً
)
```

عند `androidStopForegroundOnPause: false`:
- الموسيقى تكمل حتى عند مسح التطبيق من Recent Apps
- ما لم يضغط المستخدم Stop من الإشعار

---

## استعادة الجلسة بعد إعادة الفتح

```dart
// في SplashScreen
final lastSession = await settingsRepo.getLastSession();
if (lastSession != null) {
  await audioHandler.updateQueue(lastSession.queue);
  // لا نشغّل تلقائياً، نتركه في حالة pause
}
```

---

## headset buttons / Bluetooth

`audio_service` يعالج أزرار سماعات الرأس والبلوتوث تلقائياً:

| الزر | الفعل |
|------|-------|
| ضغطة واحدة | تشغيل / إيقاف |
| ضغطتان | الأغنية التالية |
| ثلاث ضغطات | الأغنية السابقة |
