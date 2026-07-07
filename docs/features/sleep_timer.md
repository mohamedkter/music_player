# ⏱️ Sleep Timer

## الوصف

يوقف التشغيل تلقائياً بعد مدة محددة أو عند نهاية الأغنية الحالية.

---

## التنفيذ

```dart
class SleepTimerService {
  Timer? _timer;
  Duration? _remaining;
  bool _stopAtEndOfSong = false;

  // بدء المؤقت
  void start({
    required Duration duration,
    bool stopAtEndOfSong = false,
  }) {
    cancel(); // إلغاء أي مؤقت سابق
    _remaining = duration;
    _stopAtEndOfSong = stopAtEndOfSong;

    _timer = Timer(duration, _onTimerEnd);

    // تحديث الوقت المتبقي كل ثانية للعرض في الواجهة
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        _remaining = _remaining! - const Duration(seconds: 1);
        if (_remaining! <= Duration.zero) t.cancel();
      },
    );
  }

  void _onTimerEnd() {
    if (_stopAtEndOfSong) {
      // انتظر نهاية الأغنية الحالية
      audioHandler.playbackState.first.then((_) => audioHandler.stop());
    } else {
      audioHandler.stop();
    }
    cancel();
  }

  void cancel() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _timer = null;
    _remaining = null;
  }

  Duration? get remaining => _remaining;
  bool get isActive => _timer?.isActive ?? false;
}
```

---

## واجهة Sleep Timer

```
┌─────────────────────────────────┐
│  ⏱ Sleep Timer                  │
├─────────────────────────────────┤
│                                 │
│  ┌────────┐  ┌────────┐        │
│  │  5 دق  │  │ 10 دق  │        │
│  └────────┘  └────────┘        │
│  ┌────────┐  ┌────────┐        │
│  │ 15 دق  │  │ 30 دق  │        │
│  └────────┘  └────────┘        │
│  ┌────────┐  ┌────────┐        │
│  │ 45 دق  │  │  1 سا  │        │
│  └────────┘  └────────┘        │
│  ┌────────┐                    │
│  │  2 سا  │                    │
│  └────────┘                    │
│                                 │
│  ─────────────────────────────  │
│  إيقاف عند نهاية الأغنية: [☑]  │
│                                 │
│  ─────────────────────────────  │
│          مخصص                   │
│  ┌─────────────────────────┐   │
│  │    00 : 45 : 00          │   │  ← Time Picker
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### عند تفعيل المؤقت

يظهر في Now Playing Screen:
```
⏱ ينتهي بعد: 24:30   [إلغاء]
```

---

## التكامل مع Now Playing

```dart
// عرض الوقت المتبقي
StreamBuilder<Duration?>(
  stream: sleepTimerService.remainingStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
    return SleepTimerIndicator(remaining: snapshot.data!);
  },
)
```
