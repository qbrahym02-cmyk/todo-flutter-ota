# مهامي — تطبيق To-Do بـ Flutter مع تحديث عن بُعد 🚀

تطبيق مهام كامل (عربي RTL، Material 3) تقدر **تحدّثه عن بُعد** بثلاث طرق:

| المستوى | ماذا تغيّر | كيف | هل يحتاج المستخدم يسوي شي؟ |
|---|---|---|---|
| ⚡ **1. الإعدادات الحيّة** | العنوان، الألوان، الوضع الليلي، رسالة إعلان، التصنيفات، تشغيل/إيقاف الميزات | عدّل `remote/config.json` على GitHub | **لا** — يتغير تلقائياً عند فتح التطبيق أو السحب للتحديث |
| 🌐 **2. نسخة الويب** | أي تغيير في الكود | `git push` → GitHub Actions يبني ويرفع | **لا** — يفتح الرابط ويشوف النسخة الجديدة |
| 📲 **3. تحديث أندرويد داخل التطبيق** | أي تغيير في الكود | `git push` → يُبنى APK جديد تلقائياً | يظهر له شريط "تحديث الآن" ← ضغطة واحدة ← تثبيت (بدون متجر وبدون البحث عن رابط) |

> المهام نفسها محفوظة على الجهاز ولا تنحذف عند التحديث.

---

## الروابط

- 🌐 التطبيق على الويب: `https://qbrahym02-cmyk.github.io/todo-flutter-ota/`
- 📲 تحميل APK (أول مرة فقط): `https://qbrahym02-cmyk.github.io/todo-flutter-ota/todo.apk`
- 🔎 معلومات آخر إصدار: `https://qbrahym02-cmyk.github.io/todo-flutter-ota/update.json`
- ⚙️ الإعدادات الحيّة: [`remote/config.json`](remote/config.json)

---

## ⚡ المستوى 1: غيّر التطبيق بدون أي بناء

افتح [`remote/config.json`](remote/config.json) على GitHub ← اضغط ✏️ ← عدّل ← **Commit**.
(تقدر تسويها حتى من جوالك.)

```json
{
  "config_version": 2,
  "app_title": "مهامي",
  "primary_color": "#16A34A",
  "dark_mode": true,
  "announcement": { "enabled": true, "text": "خصم 50% اليوم!", "color": "#F59E0B" },
  "features": { "priorities": true, "due_dates": true, "categories": true, "stats": false },
  "categories": ["عام", "عمل", "بيت", "رياضة"]
}
```

يجلب التطبيق الإعدادات: عند الفتح، عند الرجوع إليه من الخلفية، وعند السحب للأسفل.
(GitHub يخزّن الملفات مؤقتاً، فقد يتأخر التغيير حتى ~5 دقائق.)

---

## 📲 المستويان 2 و 3: نشر كود جديد

1. عدّل الكود في `lib/`
2. (اختياري) اكتب ملاحظات الإصدار في [`remote/release.json`](remote/release.json)
3. `git push`

GitHub Actions يقوم تلقائياً بـ:
- تشغيل `flutter analyze` و `flutter test`
- بناء APK موقّع برقم بناء جديد (= رقم التشغيل) + بناء الويب
- رفع كل شيء على GitHub Pages مع `update.json` (يشمل SHA-256 للتحقق من الملف)
- إنشاء GitHub Release

التطبيق على الجوال يقارن رقم البناء ← يظهر شريط **"إصدار جديد متوفر"** ← **تحديث الآن**.

**تحديث إلزامي:** ضع `"min_build": N` في `remote/release.json` — أي نسخة أقدم من N يظهر لها التحديث كإلزامي.

---

## 🔐 التوقيع (مهم)

أندرويد لا يقبل تثبيت تحديث فوق التطبيق إلا إذا كان **بنفس مفتاح التوقيع**.
المفتاح محفوظ في GitHub Secrets:
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`

⚠️ احتفظ بنسخة احتياطية من ملف المفتاح. إذا ضاع، لن تستطيع إصدار تحديثات للنسخ المثبتة.

---

## 🐦 المستوى 4 (اختياري): Shorebird — تحديث كود Dart بدون تنزيل APK

إذا تبي تحديث الكود نفسه **بصمت تماماً** (بدون شاشة تثبيت)، استخدم [Shorebird](https://shorebird.dev) (Code Push الرسمي لـ Flutter):

```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
shorebird login
shorebird init                       # ينشئ shorebird.yaml
shorebird release android --artifact apk   # النسخة الأساسية (يثبتها المستخدم مرة)
# بعدها لأي تعديل في Dart:
shorebird patch android              # يصل للمستخدمين عند فتح التطبيق التالي
```

---

## 🛠 التشغيل محلياً

```bash
flutter pub get
flutter run            # على جهاز أندرويد
flutter run -d chrome  # على الويب
flutter test
```

## هيكل المشروع

```
lib/
├── main.dart                     # نقطة البداية + الثيم الديناميكي
├── config.dart                   # روابط الإعدادات والتحديث
├── models/task.dart              # نموذج المهمة
├── services/
│   ├── remote_config.dart        # جلب الإعدادات الحيّة + كاش بدون إنترنت
│   ├── update_service.dart       # فحص وتنزيل وتثبيت التحديثات
│   ├── task_controller.dart      # منطق المهام (فلترة، ترتيب...)
│   └── task_storage.dart         # الحفظ المحلي
├── screens/home_screen.dart
└── widgets/                      # بطاقة المهمة، المحرر، شريط التحديث
remote/
├── config.json                   # ⚡ عدّله لتغيير التطبيق فوراً
└── release.json                  # ملاحظات الإصدار + أقل إصدار مسموح
.github/workflows/release.yml     # البناء والنشر التلقائي
```
