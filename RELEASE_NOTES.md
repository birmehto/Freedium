![Freedium banner](https://raw.githubusercontent.com/birmehto/Freedium/main/screenshots/banner.png)

# Release Notes - v1.1.2

## ✨ What's New in v1.1.2

- **🧡 Support the project** — a "Support Freedium" button on Home now lets you help with a short rewarded video or a one-off "Buy me a coffee". No ad is ever shown unless you choose to watch one, and the video is warmed up at app launch so it's ready before you ask for it.
- **📚 Offline reading** — favoriting an article keeps a copy on your device, so it opens even with no connection. An "Offline copy" banner marks a story being read from the device, and retry takes you back online.
- **📈 Reading progress** — where you stopped is remembered per article, shown in the reader, and the Library's "Continue reading" section surfaces unfinished stories most-recent-first.
- **🛰️ Mirror failover** — three mirror bypass servers with per-source health tracking and automatic fallback to the next healthy mirror whenever one errors out.
- **🎨 Reader improvements**:
  - **Readability themes** — System / Light / Dark / Sepia / OLED.
  - **Font family & size** — pick the typeface and size that suits you.
  - **Article metadata** — titles, authors, publications, word counts and reading times extracted up front.
  - **Reader actions** — favorite, share, copy link, open in browser.
- **🌗 Full-app theme modes** — System / Light / Dark across the whole app, and the toggle now genuinely drives the theme.
- **⚙️ Behind the scenes**:
  - Storage moved to SQLite via Drift — favorites, settings, cached articles and reading positions live in proper tables instead of one flat JSON blob.
  - The reader moved to the official `webview_flutter` plugin.
  - Ad identifiers are never committed to the repository — the build reads them from a git-ignored local file and falls back to Google's public test IDs on a fresh clone.

## 🐛 Fixes

- Dark/Light toggle now actually switches the app theme instead of leaving it pinned to its starting value.
- A loaded article no longer sits behind a spinner: the reader clears the progress bar as soon as the page is on screen, not only when the backend admits the load finished.
- Ad-load failures (no fill, configuration errors, timeouts, offline) now explain exactly what went wrong instead of failing silently.

## 🧪 Quality

- 311 tests, `flutter analyze` clean, formatting enforced in CI.
- The release pipeline builds the universal APK plus per-architecture splits and publishes them to this release automatically.

## 📥 Install

Grab the APK for your device architecture above, or get the latest build from the [Google Play listing](https://play.google.com/store/apps/details?id=com.bir.freedium).