<div align="center">

# 📖 Freedium

**Read any Medium story — free, clean, and distraction-free.**

[![Version](https://img.shields.io/badge/Release-v1.3.0-2E8B57?style=flat-square)](https://github.com/birmehto/Freedium/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android-blue?style=flat-square)](https://github.com/birmehto/Freedium/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/birmehto/Freedium?style=flat-square)](https://github.com/birmehto/Freedium/stargazers)

<img src="screenshots/icon.png" width="120" alt="Freedium app icon"/>

**Paste or share a Medium link, and Freedium opens the full story in a clean, comfortable reader** — no paywall, no clutter, no account.

⭐ **[Star the repo](https://github.com/birmehto/Freedium/stargazers)** — it is the single best way to help new readers discover Freedium.

<p align="center">
  <a href="https://github.com/birmehto/Freedium/releases/latest"><img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F_Download_APK-2E8B57?style=for-the-badge&logo=android&logoColor=white" alt="Download APK"/></a>
  &nbsp;
  <a href="https://play.google.com/store/apps/details?id=com.bir.freedium"><img src="https://img.shields.io/badge/Google_Play-Get_it-414141?style=for-the-badge&logo=googleplay&logoColor=white" alt="Get it on Google Play"/></a>
</p>

</div>

---

## 🎯 What matters

- **Your reading stays yours.** No account, no analytics, no ads. Favorites, settings and saved stories stay on your device — no cloud sync. Opening a story only sends its link to the mirror that fetches it.
- **A story, not a webpage.** The reader strips the paywall and the clutter, then gives you five themes, font families and text size so long-form writing stays easy to read.
- **It keeps working.** Five sources with automatic fallback and health tracking. Favorited stories are saved on-device, so a story you care about is still readable when every mirror is down.
- **Free and open source.** MIT licensed, built in spare time. A coffee is appreciated, never required.

---

## ✨ Features

- **🛡️ Unlock any Medium story** — paste a link or share one from any app.
- **⭐ Favorites** — a searchable on-device library of the stories you keep.
- **📥 Offline reading** — favoriting a story keeps a copy for offline use; removing the favorite removes the copy.
- **🎨 Make it yours** — System, Light, Dark, Sepia and OLED reader themes, plus font family and size.
- **🔄 Reliable loading** — Freedium Mirror, Freedium Web, Freedium backup, Archive.ph and Archive.is, with automatic fallback.
- **🎬 Quiet motion** — one shared animator keeps page transitions, tab swaps and toggles consistent.
- **⭐ Rate us** — rate the app or buy a coffee from the support dialog on Home or in Settings.
- **☕ Support the project** — an optional "buy me a coffee" from the home screen.

---

## 📱 Screenshots

The images currently in `screenshots/` show the previous design and are being regenerated for v1.3.0. Until then, the most accurate view of the new UI is the [Google Play listing](https://play.google.com/store/apps/details?id=com.bir.freedium). The AI prompts used to produce the new set live in [PLAY_STORE.md](PLAY_STORE.md).

---

## 📲 Download & Install (Android)

[Get it on Google Play](https://play.google.com/store/apps/details?id=com.bir.freedium) · [Download APKs from GitHub Releases](https://github.com/birmehto/Freedium/releases/latest)

Direct APKs come as `universal` (all devices), `arm64-v8a` (modern 64-bit), `armeabi-v7a` (older 32-bit) and `x86_64` (emulators). Allow "Install unknown apps" when prompted.

---

## 🛠 Build from source

**Prerequisites:** Flutter `>= 3.50` and Dart `>= 3.14` on the stable channel.

```bash
git clone https://github.com/birmehto/Freedium.git
cd Freedium

flutter pub get
dart run build_runner build   # generate Drift database code
flutter run
```

> Re-run `dart run build_runner build` after changing a Drift table.

---

## 🛠 Tech Stack

| Layer | What we use |
|---|---|
| Framework | Flutter / Dart |
| State management | Riverpod notifiers |
| UI | Material widgets with Lucide icons (`lucide_icons_flutter`) |
| Motion | One shared `AppAnimator` for routes, tabs and state changes |
| Article rendering | `webview_flutter` with injected reader CSS/JS |
| Local storage | Drift + SQLite behind a `KeyValueStore` abstraction |
| Share integration | `receive_sharing_intent` (Share → Freedium) |
| Utilities | `url_launcher`, `share_plus`, `intl`, `package_info_plus` |
| Quality | `flutter_lints`, 338 unit/widget tests |

---

## 🗺️ Roadmap

Shipped already: unlock & read, favorites, offline copies, reader customization, five-source fallback, app themes and consistent motion.

Next up:

- **Bookmarks** alongside favorites in the Library *(planned)*.
- **Window-size handling and desktop testing** for Linux/macOS/Windows *(planned)*.
- **Deeper search** across saved content *(planned)*.

Track progress in the repository issues and pull requests.

---

## 🤝 Contributing

Contributions are welcome — bug fixes, UI polish and documentation all help. Read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repo and create a branch (`feat/...` or `fix/...`).
2. Make focused changes that follow the existing architecture.
3. Keep the quality bar green:
   ```bash
   dart format --set-exit-if-changed lib test
   flutter analyze
   flutter test
   ```
4. Open a pull request against `main` and describe what you changed.

Looking for a starting point? Check the [`good first issue`](https://github.com/birmehto/Freedium/contribute) label.

---

## 🐛 Issues

- **🐞 Report a bug** — use the [Bug report](https://github.com/birmehto/Freedium/issues/new?assignees=&labels=bug&projects=&template=bug_report.yml) template. Include steps to reproduce, expected vs. actual behavior, and your device/Flutter version.
- **💡 Request a feature** — use the [Feature request](https://github.com/birmehto/Freedium/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.yml) template and describe the problem you're solving.

Please search existing issues first to avoid duplicates.

---

## ⭐ Support

Freedium is free and open source, built and maintained in spare time. If it's useful to you:

- ⭐ **[Star the repo](https://github.com/birmehto/Freedium/stargazers)** — it helps others find it.
- ☕ **[Buy me a coffee](https://buymeacoffee.com/birmehto)** — helps keep the mirrors running.

---

## 📚 Learn more

- 🤝 [Contributing](CONTRIBUTING.md) — build instructions and guidelines
- 📝 [Changelog](CHANGELOG.md) — release history
- 📋 [Release notes](RELEASE_NOTES.md) — highlights for the current release
- 🖼️ [Play Store assets & ASO copy](PLAY_STORE.md) — screenshots prompts and store listing text
- 🔒 [Privacy](PRIVACY_POLICY.md) — what stays on your device

---

## ⚖️ Legal

Freedium is **not affiliated with, endorsed by, or connected to Medium or Freedium**. It wraps publicly available reader endpoints; all article content remains the property of its original authors.

Open source under the [MIT License](LICENSE). © Bir Mehto.
