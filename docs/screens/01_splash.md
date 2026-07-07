# 1️⃣ Splash Screen

## الوصف

الشاشة الأولى التي تظهر عند فتح التطبيق. تعرض شعار التطبيق وتقوم بتحميل المكتبة الموسيقية في الخلفية.

---

## العناصر البصرية

| العنصر | التفاصيل |
|--------|----------|
| شعار التطبيق | في المنتصف، مع animation بسيط (Scale + Fade) |
| اسم التطبيق | تحت الشعار |
| مؤشر تحميل | `LinearProgressIndicator` أو نقاط دائرية |
| لون الخلفية | لون Accent الرئيسي أو لون dark |

---

## المنطق (Logic)

```
1. عرض الشاشة
2. بدء animation الشعار (500ms)
3. في نفس الوقت:
   - فحص صلاحية Storage
   - إذا ممنوحة → بدء فحص المكتبة الموسيقية
   - إذا غير ممنوحة → الانتقال لشاشة الصلاحيات
4. انتهاء التحميل → الانتقال لـ Home
```

---

## الانتقالات

- **من**: لا شيء (أول شاشة)
- **إلى**: `PermissionsScreen` إذا لم تُمنح الصلاحية
- **إلى**: `HomeScreen` إذا كل شيء جاهز

---

## ملاحظات التنفيذ

- استخدم `flutter_native_splash` لعرض splash فوري قبل اكتمال تحميل Flutter
- لا تعرض الشاشة أكثر من **3 ثوان** حتى لو لم ينته التحميل — انتقل وأكمل التحميل في الخلفية
- احفظ آخر جلسة تشغيل لاستعادتها عند الفتح

```dart
// مثال مبسط
class SplashScreen extends StatefulWidget { ... }

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _checkPermissions(),
      _loadLibrary(),
      Future.delayed(const Duration(milliseconds: 2000)), // حد أدنى للعرض
    ]);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }
}
```
