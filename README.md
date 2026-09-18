<div align="center">

# 📖 Freedium

**The friendly Medium un-paywall reader — free, open-source, and endlessly readable.**

[![Visitors](https://api.visitorbadge.io/api/VisitorHit?user=birmehto&repo=Freedium&countColor=%232E8B57)](https://github.com/birmehto/Freedium)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter&logoColor=white&labelColor=0F172A)](https://flutter.dev)
[![Material 3 Expressive](https://img.shields.io/badge/Material%203-Expressive-6750A4?logo=materialdesign&logoColor=white&labelColor=0F172A)](https://pub.dev/packages/material_3_expressive)
[![CI](https://github.com/birmehto/Freedium/actions/workflows/ci.yml/badge.svg)](https://github.com/birmehto/Freedium/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Release-v1.1.1-2E8B57?style=flat-square)](https://github.com/birmehto/Freedium/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Linux%20%7C%20iOS-blue?style=flat-square)]()

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

**Paste a Medium link, tap *Unlock*, and read the full story** — no subscription, no paywall, no clutter. Freedium fetches the complete article through the mirror network and serves it in a calm, distraction-free Material 3 reader, then lets you save it, favorite it, and pick up right where you left off — even offline.

</div>

---

## ✨ Features

- **🛡️ Unlock any Medium story** — paste a link (or share it from any app) and Freedium fetches the full article through the Freedium mirror network. Friendly messages, never cryptic errors.
- **🔗 Share-to-read (one tap)** — Share → Freedium opens the article instantly from any app with a URL.
- **🔄 Reliable mirror network** — a dedicated resolver tracks per-source health and automatically falls back to the next healthy mirror; pick a preferred source or turn auto-fallback on/off in Settings.
- **📚 Your Library, four ways** — *Continue Reading* (with progress bars), *Favorites*, *Saved* offline articles, and *History* grouped into Today / Yesterday / This week / Earlier.
- **💾 Offline reading** — save a cleaned copy of any article and reopen it with no connection. Cache is capped at 64 MB with oldest-first eviction and can be reviewed or cleared from Settings.
- **📊 Reading progress & stats** — a live progress bar, per-article scroll-position memory, a "Continue from where you stopped?" prompt, plus local articles-opened/completed/minutes-read statistics.
- **🎨 Material 3 Expressive design** — dynamic color, expressive navigation, adaptive light/dark themes, and polish you can feel on every screen.
- **🔤 Rich reader settings** — five reader themes (System / Light / Dark / Sepia / OLED), font family, size, line height, paragraph spacing, content width, and text alignment.
- **🔎 Find in article** — search the current story with match-count navigation.
- **🖼️ Cleared landing pages** — injected CSS strips paywalls, nav bars, dialogs, and modal popovers, leaving just the story.
- **⌨️ Desktop-friendly** — responsive shell (navigation rail on wide screens) and full keyboard shortcuts.
- **🔐 Privacy-first** — no accounts, no analytics; settings and content live only on your device.

---

## ⌨️ Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + K` | Focus the URL field |
| `Ctrl/Cmd + Enter` | Unlock the article |
| `Ctrl/Cmd + F` | Find in article |
| `Ctrl/Cmd + S` | Save offline |
| `Ctrl/Cmd + D` | Toggle favorite |
| `Ctrl/Cmd + =` / `Ctrl/Cmd + -` | Increase / decrease font size |
| `Esc` | Close find or dialog |

---

## 📲 Download

| Platform | Link |
|----------|------|
| 🤖 Android (APK) | [Latest release](https://github.com/birmehto/Freedium/releases/latest) |
| 🍎 iOS | 🚧 Planned (unsigned IPA on releases for sideloading) |
| 🐧 Linux (desktop) | [Build from source](#-build-from-source) |

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

**Linux desktop:**

```bash
flutter config --enable-linux-desktop
flutter build linux --release
```

**Automated release (builds all APK types + publishes to GitHub via `gh`):**

```bash
./scripts/release.sh            # version from pubspec.yaml
./scripts/release.sh v1.2.3     # or pass the tag explicitly
```

**Quality checks** (also run on every pull request via GitHub Actions):

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

---

## 🧱 Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter / Dart |
| State management | GetX (`get`) + GetStorage |
| Design system | Material 3 Expressive (`material_3_expressive`) + `material_ui` |
| Reader engine | `flutter_inappwebview` with progressive enhancement |
| Mirror resolution | Public reader endpoints with per-source health tracking + fallback |
| Storage | Split `preferences` / `library` stores behind a `KeyValueStore` abstraction |
| Sharing | `receive_sharing_intent` + `share_plus` |
| Utilities | `package_info_plus`, `url_launcher`, `intl` |

---

## 🧭 How it works

```text
Link / shared URL
      ↓
Normalize (strip tracking, resolve host)
      ↓
Pick healthy mirror (preferred → fallback)
      ↓
Load & clean the article
      ↓
Inject reader CSS + extract metadata
      ↓
Read → progress saved → save offline / favorite
```

Everything is stored locally — see [ARCHITECTURE.md](ARCHITECTURE.md) and [PRIVACY.md](PRIVACY.md).

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