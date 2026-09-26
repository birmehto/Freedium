# Changelog

All notable changes to Freedium are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Offline reading**
  - Articles are saved on the device as you read them and open again with no connection, falling back to the saved copy when every mirror fails.
  - An "Offline copy" banner marks a story being read from the device, with a retry action to go back online.
  - `ArticleCacheStore` keeps bodies in their own Drift table, capped at 24 MB in total and 2 MB per article, evicting the oldest first and never evicting favorites.
  - Settings → Offline Articles reports what is stored and clears it in one action; reading positions and favorites are left alone.
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
- **Tests** for the URL source of truth, mirror resolver, library store, article cache and reading progress stores, the offline reader flow, the continue-reading section, reader settings/models, article models, and widget flows (231 tests total).
- **CI workflow** (`.github/workflows/ci.yml`) — format check, `flutter analyze`, `flutter test`, and an Android debug build on every pull request.

### Changed
- **iOS support removed.** The `ios/` project and its metadata references are gone; the supported targets are Android and Linux. Android share intents, the WebView reader, and Drift storage are unaffected.
- **Storage** is split into `PreferencesStore` (settings) and `LibraryStore` (favorites + article metadata) behind a `KeyValueStore` interface, backed by Drift/SQLite in production and `MemoryKeyValueStore` in tests. Writes are serialized so concurrent updates cannot interleave. Article bodies and reading positions sit in their own Drift tables rather than in the key-value store, which would load every row on startup.
- **Reader** reports scroll position through the WebView's `onScrollChanged`, and the article is served with `loadData` so the saved copy and the fetched page go through the same path.
- **URL handling** has a single source of truth in `ArticleUrl`: it normalizes markdown links, bare hosts, and shared text, strips tracking parameters, and is the only validator used by the home form, share intents, favorites, and the resolver.
- **Share intents** are Android-only and reactive, so a link shared while the app is open is picked up without a restart.
- **Android manifest** no longer claims `http`/`https` `VIEW` filters it never handled, and backups are disabled with explicit data-extraction rules.
- **Release signing** is now conditional on `android/key.properties`; a fresh clone can still produce a debug-signed release build instead of failing.

### Removed
- **Find-in-article** — the find bar, its WebView `findInteractionController` wiring, and the associated controller state were removed. Android's native find-in-page remains available in the WebView.
- Dead offline/save-article scaffolding (`SavedArticle`, `LibraryStore.saveArticle`) that no code path could reach.
- Unused URL-validator wrapper, logging helpers, dead routes, and duplicate reactive state.
- All `// ignore:` lint suppressions from `lib/`.

## [1.1.1] - 2026-09-?? (Unreleased portion below)

### Changed
- See `RELEASE_NOTES.md` for the v1.1.1 release summary (architecture cleanup, share-intent integration, M3 Expressive UI, automated release script, scroll memory, engine auto-failover).

## [1.1.0] - 2026-??-?? (Previous release — historical)

- Share-to-read intent, reading progress, favorites, adjustable font size, settings.