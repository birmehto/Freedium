<div align="center">

# 📖 Freedium

**The friendly Medium un-paywall reader — free, open-source, and endlessly readable.**

[![Visitors](https://api.visitorbadge.io/api/VisitorHit?user=birmehto&repo=Freedium&countColor=%232E8B57)](https://github.com/birmehto/Freedium)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter&logoColor=white&labelColor=0F172A)](https://flutter.dev)
[![Material 3 Expressive](https://img.shields.io/badge/Material%203-Expressive-6750A4?logo=materialdesign&logoColor=white&labelColor=0F172A)](https://pub.dev/packages/material_3_expressive)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Release-v1.1.1-2E8B57?style=flat-square)](https://github.com/birmehto/Freedium/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=flat-square)]()

<p align="center">
  <img src="screenshots/banner.png" width="720" alt="Freedium banner"/>
</p>

<p align="center">
  <img src="screenshots/home.png" width="170" alt="Home screen"/>
  <img src="screenshots/article.png" width="170" alt="Article reader"/>
  <img src="screenshots/favorites.png" width="170" alt="Favorites"/>
  <img src="screenshots/settings.png" width="170" alt="Settings"/>
  <img src="screenshots/share.png" width="170" alt="Share-to-read"/>
</p>

**Paste a Medium link, tap *Unlock*, and read the full story** — no subscription, no paywall, no clutter. Freedium fetches the complete article through the mirror network and serves it in a calm, distraction-free Material 3 reader.

</div>

---

## ✨ Features

- **🛡️ Unlock any Medium story** — paste a link (or share it from any app) and Freedium fetches the full article through the Freedium mirror network. Friendly messages, never cryptic errors.
- **🔗 Share-to-read (one tap)** — Share → Freedium opens the article instantly from any app with a URL.
- **🎨 Material 3 Expressive design** — built on the `material_3_expressive` design system: dynamic color extraction, animated navigation, expressive navigation bar, adaptive light/dark themes, and polish you can feel on every screen.
- **📊 Reading progress** — a live progress bar plus per-article scroll-position memory, so you resume where you left off.
- **⭐ Offline favorites** — save locally (no account), search by title/author/source, swipe to remove, reopen in one tap.
- **🖼️ Cleared landing pages** — injected CSS strips paywalls, nav bars, dialogs, and modal popovers, leaving just the story.
- **🔤 Adjustable reading** — font size from 12 to 28 px with a live slider.

---

## 📲 Download

| Platform | Link |
|----------|------|
| 🤖 Android (APK) | [Latest release](https://github.com/birmehto/Freedium/releases/latest) |
| 🍎 iOS | 🚧 Planned (unsigned IPA on releases for sideloading) |

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

**Automated release (builds all APK types + publishes to GitHub via `gh`):**

```bash
./scripts/release.sh            # version from pubspec.yaml
./scripts/release.sh v1.2.3     # or pass the tag explicitly
```

**Quality checks:**

```bash
flutter analyze      # static analysis
flutter test         # test suite
dart format .        # formatting
```

---

## 🧱 Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter / Dart |
| State management | GetX (`get`) + GetStorage |
| Design system | Material 3 Expressive (`material_3_expressive`) |
| Reader engine | `flutter_inappwebview` with progressive enhancement |
| Sharing | `receive_sharing_intent` + `share_plus` |
| Utilities | `package_info_plus`, `url_launcher`, `intl` |

---

## 🤝 Contributing

1. 🍴 Fork the repo
2. 🌿 Create a branch (`git checkout -b feat/my-idea`)
3. ✍️ Make your changes — keep `flutter analyze` happy
4. 🧪 Add tests where it makes sense
5. 🚀 Open a pull request

Please be kind — this is a passion project. 💜

### 📚 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — how the codebase is organized
- [CONTRIBUTING.md](CONTRIBUTING.md) — setup, guidelines, and release process
- [CHANGELOG.md](CHANGELOG.md) — version history
- [PRIVACY.md](PRIVACY.md) — what is stored locally vs. sent to third parties
- [PRIVACY_POLICY.md](PRIVACY_POLICY.md) — user-facing privacy policy
- [ROADMAP.md](ROADMAP.md) — product plan and phase status
- [RELEASE_NOTES.md](RELEASE_NOTES.md) — per-release highlights

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