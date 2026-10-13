# Changelog

All notable changes to Freedium are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Support the project (opt-in rewarded ads)**
  - A floating action button on Home opens a "Support Freedium" dialog offering two ways to help: a short rewarded video, or a one-off "buy me a coffee" donation.
  - Ads go through an `AdService` seam (`lib/core/services/ad_service.dart`): the Google Mobile Ads implementation is warmed up at startup so a video is ready before the support flow opens, and platforms without the SDK (Linux desktop) degrade to "no ad available" instead of failing.
  - Ad ids are never committed: `envied` reads them from a git-ignored `.env` into an obfuscated `env.g.dart`, and `android/app/build.gradle.kts` injects the application id into the manifest from the same file. Without a `.env` the build falls back to Google's public test ids, so a fresh clone still builds and serves test ads.
- **Offline reading**
  - Favoriting an article also keeps it on the device, so it opens again with no connection and falls back to the stored copy when every mirror fails. Removing the favorite removes the copy, so there is nothing left behind to clean up.
  - Nothing is stored just because an article was read.
  - An "Offline copy" banner marks a story being read from the device, with a retry action to go back online.
  - `ArticleCacheStore` keeps bodies in their own Drift table, capped at 24 MB in total and 2 MB per article, evicting the oldest first and never evicting favorites.
- **Reading progress**
  - Scroll position is stored per article and restored on the next open, with the reader's place also shown in the article bar.
  - "Continue reading" in the library offers the articles that were started and not finished, most recent first.
  - `ReadingProgressStore` keeps one small row per article so the list is a query rather than a scan of stored JSON.
- **Mirror / source system**
  - Dedicated `ArticleResolver` with per-source health tracking and automatic fallback to the next healthy mirror.
  - Preferred-source and auto-fallback controls in Settings.
- **Reader improvements**
  - Article metadata extraction (title, author, publication, word count, reading time, published date).
  - Reader theme selection (System / Light / Dark / Sepia / OLED), font family, and font size.
  - Reader actions: favorite, share, copy link, open in browser, find.
- **Theme modes** — System / Light / Dark full-app theme selection.
- **Tests** for the URL source of truth, mirror resolver, library store, article cache and reading progress stores, the offline reader flow, the continue-reading section, reader settings/models, article models, support/ad flow, and widget flows (309 tests total).
- **CI workflow** (`.github/workflows/ci.yml`) — code generation (`dart run build_runner build`), format check, `flutter analyze`, `flutter test`, and an Android debug build on every pull request.

### Changed
- **Privacy promises now match the app.** The README and privacy policy no longer claim there are no ads or no advertising identifiers. No ad is ever shown unless the user chooses to watch one, though the SDK is warmed up at startup: the app initializes Google Mobile Ads and requests a single rewarded ad so the video is ready without a wait. That startup request — which is what lets Google Mobile Ads use the device advertising identifier — is the only ad traffic a user who never watches anything generates.
- **Ad configuration moved out of the source.** The rewarded unit is obfuscated into a git-ignored `env.g.dart` by `envied`, and the Android build passes `ADMOB_APP_ID` from the same git-ignored `.env` into the manifest as the `admobAppId` placeholder, so no real AdMob id is ever committed. The manifest still declares `com.google.android.gms.permission.AD_ID`.
- **iOS support removed.** The `ios/` project and its metadata references are gone; the supported targets are Android and Linux. Android share intents, the WebView reader, and Drift storage are unaffected.
- **Storage** is split into `PreferencesStore` (settings) and `LibraryStore` (favorites + article metadata) behind a `KeyValueStore` interface, backed by Drift/SQLite in production and `MemoryKeyValueStore` in tests. Writes are serialized so concurrent updates cannot interleave. Article bodies and reading positions sit in their own Drift tables rather than in the key-value store, which would load every row on startup.
- **Reader** renders with the official `webview_flutter` plugin, migrated from `flutter_inappwebview`; the saved copy is served with `loadHtmlString` so it and the fetched page go through the same path.
- **URL handling** has a single source of truth in `ArticleUrl`: it normalizes markdown links, bare hosts, and shared text, strips tracking parameters, and is the only validator used by the home form, share intents, favorites, and the resolver.
- **Share intents** are Android-only and reactive, so a link shared while the app is open is picked up without a restart.
- **Android manifest** no longer claims `http`/`https` `VIEW` filters it never handled, and backups are disabled with explicit data-extraction rules.
- **Release signing** is now conditional on `android/key.properties`; a fresh clone can still produce a debug-signed release build instead of failing.
- **A loaded article no longer sits behind a spinner.** The loading indicators are now dismissed as soon as the WebView reports the document on screen (`onPageCommitVisible`), not only once `onLoadStop` arrives — a backend that paints the article and never reports the load finishing otherwise left the reader with a progress bar and a blocking spinner on top of an article that had already rendered.
- **WebView plugin** — the reader moved from `flutter_inappwebview` to the official `webview_flutter`, and `android/app/proguard-rules.pro` no longer keeps the old plugin's classes. The document-start scripts (early styles, popup-window guard) are now injected when the page starts rather than as native document-start user scripts; the ES-compat polyfills were dropped (any WebView new enough to run the reader already ships them) and the popup script was trimmed to just its `window.open`/`target="_blank"` guards, since dialog suppression now belongs to the platform handlers and overlay hiding to the stylesheet. The reader's scroll-diagnostics logging and its `window.scrollTo(0, 0)` reset injection are gone. `webview_flutter` has no Linux implementation, so the article reader no longer renders on Linux desktop; it remains unaffected on Android.

### Removed
- **Find-in-article** — the find bar, its WebView `findInteractionController` wiring, and the associated controller state were removed. Android's native find-in-page remains available in the WebView.
- **Settings → Storage** — the section that reported how much was stored and cleared every saved article in one action. Favorites now own the stored copies: adding one keeps the article, removing one drops it, and there is no cache screen left to keep in step.
- Dead offline/save-article scaffolding (`SavedArticle`, `LibraryStore.saveArticle`) that no code path could reach.
- Unused URL-validator wrapper, logging helpers, dead routes, and duplicate reactive state.
- All `// ignore:` lint suppressions from `lib/`.

## [1.1.1] - 2026-09-?? (Unreleased portion below)

### Changed
- See `RELEASE_NOTES.md` for the v1.1.1 release summary (architecture cleanup, share-intent integration, M3 Expressive UI, automated release script, scroll memory, engine auto-failover).

## [1.1.0] - 2026-??-?? (Previous release — historical)

- Share-to-read intent, reading progress, favorites, adjustable font size, settings.