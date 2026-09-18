# Changelog

All notable changes to Freedium are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Library screen** with four sections: Continue Reading, Favorites, Saved, and History.
  - Continue Reading shows per-article scroll progress bars and resumes where you stopped.
  - History is grouped by recency (Today / Yesterday / This week / Earlier).
  - Unified search over title, author, and publication; recent-search shortcuts stored locally.
  - Swipe-to-remove and clear actions per list.
- **Offline reading**
  - "Save offline" captures the cleaned article HTML for later reading without a connection.
  - Saved copies open directly from Library or from the reader's error state.
  - Cache budget enforcement with oldest-entry eviction (64 MB soft cap) and a settings overview of count + size.
- **Mirror / source system**
  - Dedicated `ArticleResolver` with per-source health tracking (availability, failures, last success) and automatic fallback to the next healthy mirror.
  - Preferred-source and auto-fallback controls in Settings.
- **Reader improvements**
  - Article metadata extraction (title, author, publication, word count, reading time, published date).
  - Rich reading settings: reader theme (System / Light / Dark / Sepia / OLED), font family, font size, line height, paragraph spacing, content width, and text alignment.
  - "Continue reading?" resume prompt with Continue / Start over actions.
  - Find-in-page with match count navigation (Ctrl/Cmd+F).
  - Reader actions: save offline, favorite, share, copy link, copy article text, open in browser, find.
- **Desktop & keyboard support**
  - Responsive shell: navigation rail on wide layouts, navigation bar on narrow ones.
  - Keyboard shortcuts: Ctrl/Cmd+K focus the URL field, Ctrl/Cmd+F find, Ctrl/Cmd+S save, Ctrl/Cmd+D favorite, Ctrl/Cmd+= / Ctrl/Cmd+− font size, Esc closes find.
  - Centered, width-constrained home form on large screens.
- **Storage split** into two focused stores behind a `KeyValueStore` abstraction (`preferences` for device settings, `library` for content), keeping the old facade API for compatibility.
- **Theme modes** — System / Light / Dark full-app theme selection.
- **Settings page reorganized** into Appearance, Reader, Source, Library & Storage, and About sections, including a local reading-statistics overview (articles opened, completed, minutes read).
- **Local reading statistics** — count of articles opened/completed and total reading minutes, stored on-device only.
- **Tests** for the URL parser, mirror resolver, library store, reader settings/models, and article models (101 tests total).
- **CI workflow** (`.github/workflows/ci.yml`) — format check, `flutter analyze`, `flutter test`, and a Linux debug build on every pull request.

## [1.1.1] - 2026-09-?? (Unreleased portion below)

### Changed
- See `RELEASE_NOTES.md` for the v1.1.1 release summary (architecture cleanup, share-intent integration, M3 Expressive UI, automated release script, scroll memory, engine auto-failover).

## [1.1.0] - 2026-??-?? (Previous release — historical)

- Share-to-read intent, reading progress, favorites, adjustable font size, settings.