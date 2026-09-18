<div align="center">

# 📖 Freedium

**The friendly Medium un-paywall reader — free, open-source, and endlessly readable.**

<p align="center">
  <img src="screenshots/banner.png" width="720" alt="Freedium banner"/>
</p>

[![Visitors](https://api.visitorbadge.io/api/VisitorHit?user=birmehto&repo=Freedium&countColor=%232E8B57&style=flat-square)](https://github.com/birmehto/Freedium)
[![Stars](https://img.shields.io/github/stars/birmehto/Freedium?style=flat-square&logo=github&label=Stars&color=gold)](https://github.com/birmehto/Freedium/stargazers)
[![Version](https://img.shields.io/badge/Release-v1.1.1-2E8B57?style=flat-square)](https://github.com/birmehto/Freedium/releases/latest)
[![Platform](https://img.shields.io/badge/Android%20%7C%20iOS-blue?style=flat-square)]()
[![License: MIT](https://img.shields.io/github/license/birmehto/Freedium?color=yellow&style=flat-square)](LICENSE)

Paste a Medium link, tap **Unlock**, and read the full story — no subscription, no paywall, no clutter.

</div>

---

## 📋 Table of contents

- [About](#-about)
- [Screenshots](#-screenshots)
- [Features](#-features)
- [Download](#-download)
- [Build from source](#-build-from-source)
- [Tech stack](#-tech-stack)
- [Contributing](#-contributing)
- [Feedback & support](#-feedback--support)
- [Legal](#️-legal)

---

## 📖 About

Freedium fetches the complete article through the mirror network and serves it in a calm, distraction-free Material 3 reader. No account. No subscription. No tracking.

1. **Paste a link** — any Medium URL, from anywhere.
2. **Tap *Unlock*** — Freedium pulls the full story through the mirror network.
3. **Just read** — paywalls, nav bars, and popovers are gone, leaving pure content.

---

## 📸 Screenshots

<p align="center">
  <img src="screenshots/home.png" width="170" alt="Home screen"/>
  <img src="screenshots/article.png" width="170" alt="Article reader"/>
  <img src="screenshots/favorites.png" width="170" alt="Favorites"/>
  <img src="screenshots/settings.png" width="170" alt="Settings"/>
  <img src="screenshots/share.png" width="170" alt="Share-to-read"/>
</p>

---

## ✨ Features

| Feature | What it does |
|---------|--------------|
| 🛡️ Unlock any Medium story | Paste a link (or share it from any app) and read the full article instantly. Friendly messages, never cryptic errors. |
| 🔗 Share-to-read | Share → Freedium opens the article from any app with a URL — one tap. |
| 🎨 Material 3 Expressive | Dynamic color extraction, animated navigation, adaptive light/dark themes. |
| 📊 Reading progress | Live progress bar plus per-article scroll memory — resume where you left off. |
| ⭐ Offline favorites | No account needed; search by title/author/source, swipe to remove, reopen in one tap. |
| 🖼️ Cleared landing pages | Injected CSS strips paywalls, dialogs, and modal popovers, leaving just the story. |
| 🔤 Adjustable reading | Font size from 12 to 28 px with a live slider. |

---

## 📲 Download

| Platform | Link |
|----------|------|
| 🤖 Android (APK) | [Latest release](https://github.com/birmehto/Freedium/releases/latest) |
| 🍎 iOS | 🚧 Planned (unsigned IPA on releases for sideloading) |

On Android, allow installs from unknown sources for direct APK downloads.

---

## 🔨 Build from source

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

---

## 💌 Feedback & support

Found a broken mirror? Want iOS? Have a bug?

- Open a [GitHub issue](https://github.com/birmehto/Freedium/issues)
- Email: birmehto@gmail.com

Enjoying Freedium? **[Buy me a coffee ☕](https://buymeacoffee.com/birmehto)**.

---

## ⚖️ Legal

Freedium is **not affiliated with, endorsed by, or connected to Medium**. It wraps publicly available reader endpoints; all article content remains the property of its original authors.

Screenshots shown are illustrative. Released under the [MIT License](LICENSE). © Bir Mehto.