# 📖 Freedium

**The friendly Medium un-paywall reader.** Paste a Medium article link, hit *Unlock*, and read the full story in a clean, distraction-free reader — no subscription, no clutter.

<p align="center">
  <img src="screenshots/banner.png" width="720" alt="Freedium banner"/>
</p>

<p align="center">
  <img src="screenshots/home.png" width="170" alt="Home screen"/>
  <img src="screenshots/article.png" width="170" alt="Article reader"/>
  <img src="screenshots/favorites.png" width="170" alt="Favorites"/>
  <img src="screenshots/settings.png" width="170" alt="Settings"/>
</p>

---

## ✨ Features

- **🛡️ Unlock any Medium story** — paste a link (or share it from any app) and Freedium fetches the full article through the Freedium mirror network. Friendly messages, never cryptic errors.
- **🔗 Share-to-read (one tap)** — Share → Freedium opens the article instantly from any app with a URL.
- **🎨 Calm reading, Freedium-style** — warm paper canvas, muted green accents, serif headlines, dark/light themes, pull-to-refresh.
- **📊 Reading progress** — a live progress bar plus per-article scroll-position memory, so you resume where you left off.
- **⭐ Offline favorites** — save locally (no account), search by title/author/source, swipe to remove, reopen in one tap.
- **🖼️ Cleared landing pages** — injected CSS strips paywalls, nav bars, dialogs, and modal popovers, leaving just the story.

---

## 📲 Download

| Platform | Link |
|----------|------|
| 🤖 Android APK | [Latest release](https://github.com/birmehto/Freedium/releases/latest) |
| 🍎 iOS | 🚧 Planned |

> On Android, allow installs from unknown sources for direct APK downloads.

---

## 🛠️ Build from source

**Prerequisites:** Flutter `>= 3.44.0` + Dart `>= 3.13.0`.

```bash
git clone https://github.com/birmehto/Freedium.git
cd Freedium
flutter pub get
flutter run
```

**Release APK:**

```bash
flutter build apk --release
flutter build apk --release --split-per-abi   # smaller per-ABI builds
```

**Quality checks** (run by CI on every push):

```bash
flutter analyze      # static analysis
flutter test         # test suite
dart format .        # formatting
```

---

## 🧭 Project structure

```
lib/
├── main.dart                      # App entry point
├── app.dart                       # Root widget + theming
├── core/
│   ├── constants/                 # Freedium URL, reader CSS/JS
│   ├── routes/                    # Routing (GetX)
│   ├── services/                  # Storage, theme, share intent
│   ├── utils/                     # URL validation & cleanup
│   └── widgets/                   # Shared UI (shell, empty states…)
└── features/
    ├── home/                      # URL input + unlock
    ├── article/                   # WebView reader + progress bar
    ├── favorites/                 # Local saved articles
    └── settings/                  # Appearance & about
```

Each feature follows a clean layout: `controllers/`, `bindings/`, `views/`, `widgets/`, `models/`.

**Tech stack:** Flutter (Material 3) · GetX · `flutter_inappwebview` · `get_storage` · `share_plus` · `receive_sharing_intent` · `url_launcher`.

---

## 🤝 Contributing

1. 🍴 Fork the repo
2. 🌿 Create a branch (`git checkout -b feat/my-idea`)
3. ✍️ Make your changes — keep `flutter analyze` happy
4. 🧪 Add tests where it makes sense
5. 🚀 Open a pull request

Please be kind — this is a passion project. 💜

---

## 💌 Feedback & support

Found a broken mirror? Want iOS? Have a bug?

- Open a [GitHub issue](https://github.com/birmehto/Freedium/issues)
- Email: birmehto@gmail.com

Enjoying Freedium? **[Buy me a coffee ☕](https://buymeacoffee.com/birmehto)** — it keeps the mirrors and the momentum going!

---

## ⚖️ Legal

Freedium is **not affiliated with, endorsed by, or connected to Medium or Freedium**. It wraps publicly available reader endpoints; all article content remains the property of its original authors.

Open-source under the [MIT License](LICENSE). © Bir Mehto.