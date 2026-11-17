# Flutter · Sandbox Template

A **Flutter 3.47 stable (Dart 3.13)** template engineered to run **interactively in AI-agent sandbox environments** (like Z.ai Code sandboxes), where the only user-visible port is served through a reverse-proxy gateway. In the sandbox the app is previewed as a **debug web build served as static files** — no device, no emulator, no dev-server protocol. Locally it is a normal Flutter app with full sub-second hot reload on web, Android and iOS. The React Native sibling template is `rn-expo-sandbox-template`.

| Layer | Technology |
|---|---|
| Framework | Flutter 3.47.7 stable · Dart 3.13 |
| UI | Material 3 — `ColorScheme.fromSeed` from a teal seed `Color(0xFF0D9488)` |
| Navigation | Adaptive — bottom `NavigationBar` (< 840 dp) / `NavigationRail` (>= 840 dp), `IndexedStack` keeps tab state |
| State | Plain `ChangeNotifier` (`AppSettings`) + `ListenableBuilder` — no state package |
| Lists | `ListView.builder` — virtualized Explore screen with `SnackBar` feedback |
| Theme | Light / dark / system mode, animated by `MaterialApp` (250 ms) |
| Platforms | Web (sandbox preview) · Android · iOS |
| Dependencies | **Zero third-party runtime packages** — `flutter` + `cupertino_icons` (+ `flutter_lints`, dev only) |
| Quality | `flutter analyze` — zero issues |

## What's inside

Three screens behind an adaptive shell. **Home** — what the template is, an interactive counter (proof that the preview really responds to input) and the sandbox dev-loop cheat-sheet. **Explore** — a `ListView.builder` showcase of everything the template ships, with `SnackBar` feedback on every tap. **Settings** — light / dark / system theme mode through a `SegmentedButton`, plus template metadata. Theme changes animate through `MaterialApp` — no rebuild flicker, no third-party package.

## The sandbox preview architecture

Z.ai-style sandboxes expose exactly **one user-visible port**: an outer Caddy gateway forwards the user's preview panel to **port 3000**. This template is built to live behind it:

- A Node **gateway-hub** process owns port 3000.
- Requests to **`/flutter/*`** are served statically from `build/web/` — the debug web build of this template.
- **Everything else** (including WebSocket upgrades) is reverse-proxied to the Expo dev server of the RN sibling template on port 3001.
- One preview panel, two templates: **`/` = React Native template, `/flutter/` = this Flutter template.**

## The dev loop (and the hot-reload trade-off)

```
edit lib/**  →  bash scripts/build-web.sh  →  reload the preview at /flutter/
              (incremental debug web build, ~15–45 s)
```

There is **no hot reload through the sandbox preview** — the dwds→DDS debug protocol does not survive the double proxy chain. That is a documented, accepted trade-off of this template. On a local machine, `flutter run` gives you full sub-second hot reload.

## Quick start (any machine)

```bash
git clone <repo> flutter-template && cd flutter-template
flutter pub get
flutter run                    # local device/emulator with hot reload
# or web preview loop:
bash scripts/build-web.sh      # debug web build → build/web
node scripts/static-server.mjs # serves build/web on PORT (default 3000)
```

## Quick start (AI sandbox / agent environment)

The clone-and-run recipe for a fresh sandbox:

1. Clone the repo to `/home/z/flutter-template`.
2. If no Flutter SDK is installed: `bash scripts/bootstrap-flutter.sh` — downloads the Flutter 3.47.7 stable tar.xz (~1 GB download, ~2.5 GB extracted, ~3–4 min) into `/home/z/flutter` (add `/home/z/flutter/bin` to `PATH` if needed).
3. `flutter pub get`.
4. `bash scripts/build-web.sh --base-href /flutter/` (or without the flag for a root-served build) → `build/web`.
5. Serve `build/web` on port 3000 with `node scripts/static-server.mjs` — or mount it behind a router that serves it under `/flutter/`, like the gateway-hub does.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/bootstrap-flutter.sh` | Install the Flutter SDK if missing — 3.47.7 stable into `/home/z/flutter` |
| `scripts/build-web.sh` | Incremental debug web build → `build/web`. Pins CanvasKit locally via `--dart-define=FLUTTER_WEB_CANVASKIT_URL` — no gstatic round-trip, works offline. Accepts `--base-href /flutter/` |
| `scripts/static-server.mjs` | Zero-dependency Node static server for `build/web`: correct MIME types, `no-store`, SPA fallback, `Access-Control-Allow-Origin: *`. `PORT` env var, default 3000 |
| `scripts/publish-template.sh` | Publish the template to GitHub (`GITHUB_TOKEN` read from the environment). Creates a **private** repo by default; fresh `V1` + `v1` history, or incremental `V{n+1}` + `v{n+1}` |

## Structure

```
├── pubspec.yaml                    # zero third-party runtime deps
├── lib/
│   ├── main.dart                   # entry point — runApp(SandboxApp)
│   ├── app.dart                    # MaterialApp + ListenableBuilder on AppSettings
│   ├── theme.dart                  # ColorScheme.fromSeed (teal) — light + dark
│   ├── state/app_settings.dart     # ChangeNotifier: theme mode (system/light/dark)
│   ├── data/features.dart          # curated content for the Explore screen
│   ├── screens/
│   │   ├── home_screen.dart        # landing: intro, interactive counter, dev loop
│   │   ├── explore_screen.dart     # ListView.builder showcase + SnackBar feedback
│   │   └── settings_screen.dart    # theme-mode SegmentedButton + about card
│   └── widgets/
│       └── adaptive_scaffold.dart  # NavigationBar | NavigationRail + IndexedStack
├── web/                            # index.html ($FLUTTER_BASE_HREF), manifest, icons
├── android/                        # Gradle project — committed, APK/device ready
├── ios/                            # Xcode project — committed, needs macOS + Xcode
├── scripts/                        # bootstrap · build-web · static-server · publish
└── docs/
    └── ARCHITECTURE.md             # layer map, decision log, serving topologies
```

## Constraints & environment facts

Honest numbers, so neither you nor your agent is surprised:

- The Flutter SDK is **2.3–2.5 GB on disk** and is kept **outside git** — `scripts/bootstrap-flutter.sh` re-installs it in ~3–4 minutes when a sandbox is missing it.
- **Only git-committed files survive sandbox reboots** — commit source, docs and scripts after every task.
- The sandbox **reaper kills any process spawned by a tool command** when the command ends, even with `nohup`/`setsid`/`&` (they remain descendants of the tool shell). Long-running processes must be launched with the double-fork pattern:
  ```bash
  ( setsid nohup bash -c 'cd /home/z/flutter-template; exec node scripts/static-server.mjs' >/dev/null 2>&1 </dev/null & )
  ```
- The inotify watch limit is **8192** — run **one** file-watching dev server at a time.
- Memory limit: **~4 GB**.
- The debug web build is **~48 MB on disk** — reproducible from source, so `build/` is never committed.

## Versioning

Commits as `V{n}: summary`, sequential append-only tags `v1`, `v2`, … — never move or delete a tag. Restore a version with `git checkout v{n} -- .` + a new commit and tag with a higher number.

## License

MIT — see [LICENSE](LICENSE).

---

# بالعربية — قالب Flutter للبيئات المعزولة (Sandbox)

قالب **Flutter 3.47 stable‏ (Dart 3.13)** مصمَّم هندسياً ليعمل **تفاعلياً داخل بيئات عمل الوكلاء الذكيين** (مثل بيئات Z.ai Code) حيث يكون المنفذ الوحيد الظاهر للمستخدم مُخدَماً عبر بوابة عكسية (reverse-proxy gateway). داخل الـ sandbox يُعايَن التطبيق كـ **بناء ويب debug يُخدَم كملفات ثابتة** — بلا جهاز حقيقي ولا محاكي ولا بروتوكول خادم تطوير. وعلى جهازك المحلي فهو تطبيق Flutter عادي بكامل إمكانات إعادة التحميل الفورية (hot reload) على الويب وأندرويد وiOS. القالب الشقيق بـ React Native هو `rn-expo-sandbox-template`.

| الطبقة | التقنية |
|---|---|
| الإطار | Flutter 3.47.7 stable · ‏Dart 3.13 |
| الواجهة | Material 3 — ‏`ColorScheme.fromSeed` من بذرة لون teal ‏`Color(0xFF0D9488)` |
| التنقل | تكيفي — ‏`NavigationBar` سفلي (< 840 dp) / ‏`NavigationRail` (>= 840 dp)، و`IndexedStack` يحفظ حالة التبويبات |
| الحالة | ‏`ChangeNotifier` عادي (`AppSettings`) مع `ListenableBuilder` — بلا أي حزمة حالة |
| القوائم | ‏`ListView.builder` — شاشة Explore مُفعَّل فيها الـ virtualization افتراضياً، مع تغذية راجعة عبر `SnackBar` |
| السمة | وضع فاتح / داكن / نظام، متحرك عبر `MaterialApp` ‏(250 ms) |
| المنصات | ويب (معاينة الـ sandbox) · أندرويد · ‏iOS |
| الاعتماديات | **صفر حزم خارجية** — فقط `flutter` و`cupertino_icons` (+ ‏`flutter_lints` للتطوير فقط) |
| الجودة | ‏`flutter analyze` — صفر مشاكل |

## ماذا يحوي القالب

ثلاث شاشات خلف هيكل تكيفي. **الرئيسية (Home)** — تعريف بالقالب، وعداد تفاعلي (إثبات أن المعاينة تستجيب للإدخال فعلاً)، وملخص حلقة التطوير في الـ sandbox. **الاستكشاف (Explore)** — قائمة `ListView.builder` تعرض كل ما يوفره القالب، مع تغذية راجعة عبر `SnackBar` عند النقر على أي بطاقة. **الإعدادات (Settings)** — اختيار وضع السمة (فاتح / داكن / نظام) عبر `SegmentedButton`، مع بيانات القالب. تغييرات السمة تتحرك عبر `MaterialApp` — بلا وميض إعادة بناء وبلا أي حزمة خارجية.

## معمارية المعاينة في الـ Sandbox

تتيح بيئات مثل Z.ai **منفذاً واحداً فقط ظاهراً للمستخدم**: بوابة Caddy خارجية تمرِّر لوحة معاينة المستخدم إلى **المنفذ 3000**. هذا القالب مبني ليعيش خلفها:

- عملية Node تُسمى **gateway-hub** تملك المنفذ 3000.
- الطلبات إلى **`/flutter/*`** تُخدَم كملفات ثابتة من `build/web/` — بناء الويب debug لهذا القالب.
- **كل ما عدا ذلك** (بما فيه ترقيات WebSocket) يُمرَّر عبر بروكسي عكسي إلى خادم Expo الخاص بالقالب الشقيق (React Native) على المنفذ 3001.
- لوحة معاينة واحدة وقالبان: **`/` = قالب React Native، و`/flutter/` = قالب Flutter هذا**.

## حلقة التطوير (ومقايضة الـ hot reload)

```
تعديل lib/**  →  bash scripts/build-web.sh  →  تحديث المعاينة على /flutter/
               (بناء ويب debug تزايدي، ~15–45 ثانية)
```

**لا يوجد hot reload عبر معاينة الـ sandbox** — بروتوكول التصحيح dwds→DDS لا يصمد خلف سلسلة البروكسي المزدوجة. هذه مقايضة موثَّقة ومقبولة في هذا القالب. أما على جهازك المحلي فيمنحك `flutter run` إعادة تحميل فورية كاملة تتم في أجزاء من الثانية.

## التشغيل السريع (على أي جهاز)

```bash
git clone <repo> flutter-template && cd flutter-template
flutter pub get
flutter run                    # جهاز/محاكي محلي مع hot reload
# أو حلقة معاينة الويب:
bash scripts/build-web.sh      # بناء ويب debug → build/web
node scripts/static-server.mjs # يخدم build/web على المنفذ PORT (الافتراضي 3000)
```

## التشغيل السريع (بيئات الوكلاء / Sandbox)

وصفة الاستنساخ والتشغيل في sandbox جديد:

1. استنسخ المستودع إلى `/home/z/flutter-template`.
2. إن لم يكن Flutter SDK مثبتاً: `bash scripts/bootstrap-flutter.sh` — ينزِّل حزمة Flutter 3.47.7 stable بصيغة tar.xz ‏(~1 GB تنزيلاً، ~2.5 GB بعد الاستخراج، ~3–4 دقائق) إلى `/home/z/flutter` (أضف `/home/z/flutter/bin` إلى المتغير PATH إن لزم).
3. `flutter pub get`.
4. `bash scripts/build-web.sh --base-href /flutter/` (أو بدونه لبناء يُخدَم من الجذر) → ‏`build/web`.
5. اخدم `build/web` على المنفذ 3000 عبر `node scripts/static-server.mjs` — أو ثبِّته خلف موجِّه (router) يخدمه تحت `/flutter/` كما يفعل الـ gateway-hub.

## السكربتات

| السكربت | الغرض |
|---|---|
| `scripts/bootstrap-flutter.sh` | تثبيت Flutter SDK إن كان مفقوداً — الإصدار 3.47.7 stable في `/home/z/flutter` |
| `scripts/build-web.sh` | بناء ويب debug تزايدي → ‏`build/web`. يثبِّت CanvasKit محلياً عبر `--dart-define=FLUTTER_WEB_CANVASKIT_URL` — بلا اتصال بـ gstatic ويعمل دون إنترنت. يقبل `--base-href /flutter/` |
| `scripts/static-server.mjs` | خادم ملفات Node بلا أي اعتماديات لـ `build/web`: أنواع MIME صحيحة، و`no-store`، وSPA fallback، و`Access-Control-Allow-Origin: *`. منفذ `PORT` والافتراضي 3000 |
| `scripts/publish-template.sh` | نشر القالب إلى GitHub (‏`GITHUB_TOKEN` يُقرأ من البيئة). ينشئ مستودعاً **خاصاً** افتراضياً؛ تاريخ جديد `V1` + `v1`، أو تزايدي `V{n+1}` + `v{n+1}` |

## هيكل المشروع

```
├── pubspec.yaml                    # صفر اعتماديات خارجية
├── lib/
│   ├── main.dart                   # نقطة الدخول — runApp(SandboxApp)
│   ├── app.dart                    # MaterialApp + ListenableBuilder على AppSettings
│   ├── theme.dart                  # ColorScheme.fromSeed ‏(teal) — فاتح + داكن
│   ├── state/app_settings.dart     # ChangeNotifier: ‏وضع السمة (system/light/dark)
│   ├── data/features.dart          # محتوى شاشة Explore المنسَّق
│   ├── screens/
│   │   ├── home_screen.dart        # الرئيسية: تعريف، عداد تفاعلي، حلقة التطوير
│   │   ├── explore_screen.dart     # قائمة ListView.builder + تغذية راجعة SnackBar
│   │   └── settings_screen.dart    # SegmentedButton لوضع السمة + بطاقة "حول"
│   └── widgets/
│       └── adaptive_scaffold.dart  # NavigationBar | NavigationRail + IndexedStack
├── web/                            # ‏index.html ‏($FLUTTER_BASE_HREF) والبيان والأيقونات
├── android/                        # مشروع Gradle — ملتزَم في git وجاهز للأجهزة/APK
├── ios/                            # مشروع Xcode — ملتزَم في git ويتطلب macOS + Xcode
├── scripts/                        # bootstrap · build-web · static-server · publish
└── docs/
    └── ARCHITECTURE.md             # خريطة الطبقات وسجل القرارات وطوبولوجيات التقديم
```

## القيود وحقائق البيئة

أرقام صريحة حتى لا تُفاجئ أنت ولا يفاجئ وكيلك:

- حجم Flutter SDK على القرص **2.3–2.5 GB** ويُستثنى من git — سكربت `scripts/bootstrap-flutter.sh` يعيد تثبيته في ~3–4 دقائق عند فقده في sandbox جديد.
- **الملفات الملتزَمة في git فقط تنجو من إعادة تشغيل الـ sandbox** — التزم بالمصدر والتوثيق والسكربتات بعد كل مهمة.
- **"الحاصد" (reaper) في الـ sandbox يقتل أي عملية تنطلق من أمر أداة** عند انتهائه، حتى مع `nohup`/`setsid`/`&` (لأنها تبقى أحفاداً لصدفة الأداة). العمليات طويلة الأمد يجب إطلاقها بنمط الـ double-fork:
  ```bash
  ( setsid nohup bash -c 'cd /home/z/flutter-template; exec node scripts/static-server.mjs' >/dev/null 2>&1 </dev/null & )
  ```
- حد inotify هو **8192** — شغِّل خادم تطوير واحداً كثيف المراقبة في كل مرة.
- حد الذاكرة: **~4 GB**.
- حجم بناء الويب debug على القرص **~48 MB** — قابل لإعادة الإنتاج من المصدر، لذلك لا يُلتزَم مجلد `build/` أبداً.

## إدارة الإصدارات

التزامات بصيغة `V{n}: وصف مختصر`، ووسوم تسلسلية `v1`، `v2`… إلحاقية فقط — لا تُنقل ولا تُحذف أبداً. استرجاع نسخة: `git checkout v{target} -- .` ثم التزام ووسم جديدين برقم أعلى.

## الترخيص

MIT — انظر [LICENSE](LICENSE).
