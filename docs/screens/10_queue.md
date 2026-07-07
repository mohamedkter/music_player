# 🔟 Queue Screen

## الوصف

تعرض قائمة الأغاني القادمة في جلسة التشغيل الحالية، مع إمكانية إعادة الترتيب والحذف.

---

## التخطيط

```
┌─────────────────────────────────┐
│  ← Queue (12)         [مسح الكل]│
├─────────────────────────────────┤
│  يُشغَّل الآن                   │
│  ┌───────────────────────────┐  │
│  │ 🎵 اسم الأغنية الحالية   │  │  ← مميّزة بلون مختلف
│  │    الفنان · 3:45          │  │
│  └───────────────────────────┘  │
│                                 │
│  التالي                        │
│  ☰  🎵 اسم الأغنية القادمة    │
│       الفنان · 4:12        [✕] │
│  ☰  🎵 اسم أغنية أخرى         │
│       الفنان · 2:58        [✕] │
│  ☰  🎵 ...                     │
│  ...                            │
│                                 │
│             [ + إضافة أغاني ]  │
├─────────────────────────────────┤
│  ▶ Mini Player (مصغّر)          │
└─────────────────────────────────┘
```

---

## الوظائف

### إعادة الترتيب (Drag & Drop)
- الإمساك بأيقونة `☰` والسحب
- تتحدث القائمة مباشرة في الـ Player

```dart
ReorderableListView.builder(
  itemBuilder: (context, index) => QueueItem(
    key: ValueKey(queue[index].id),
    song: queue[index],
    onRemove: () => playerNotifier.removeFromQueue(index),
  ),
  onReorder: (oldIndex, newIndex) =>
      playerNotifier.reorderQueue(oldIndex, newIndex),
)
```

### حذف أغنية من القائمة
- زر `✕` في كل عنصر
- أو Swipe يسار

### مسح الكل
- حوار تأكيد قبل الحذف
- تبقى الأغنية الحالية فقط

### إضافة أغاني
- يفتح شاشة اختيار أغاني بالبحث أو التصفح

---

## ملاحظات

- الأغنية التي تُشغَّل حالياً **لا يمكن** حذفها أو نقلها
- عند تفعيل Shuffle، تُعاد ترتيب القائمة عشوائياً ولكن يظل المستخدم قادراً على إعادة ترتيبها يدوياً
- `just_audio` يدعم `ConcatenatingAudioSource` لإدارة الـ Queue مباشرة:

```dart
final playlist = ConcatenatingAudioSource(
  children: songs.map((s) => AudioSource.uri(Uri.file(s.data))).toList(),
);
await player.setAudioSource(playlist, initialIndex: currentIndex);
```
