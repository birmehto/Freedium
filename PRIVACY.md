# Privacy

Freedium is built around one principle: **your reading stays on your device.**

This document is the developer-facing privacy model. The end-user version is in [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## What data is stored locally

All user data lives on-device in `get_storage` and is split across two stores:

| Store | Data |
|-------|------|
| `PreferencesStore` | Theme mode (system/light/dark), reader settings (theme, font family, size, line height, spacing, width, alignment), default font size, preferred mirror, auto-fallback flag, recent searches |
| `LibraryStore` | Favorites (title, URL, author, domain), reading history, reading progress (progress %, scroll position, timestamps), saved offline articles (cleaned HTML + metadata), local reading stats (articles opened, completed, minutes read), cached article metadata |

Clearing the app data (or uninstalling) wipes everything.

## What data leaves the device

- **Article URLs** — the only data sent is the article URL you choose to open, sent to the selected mirror service to fetch the page. The mirror's own terms and privacy practices apply to that request. Freedium is independent and not affiliated with the mirrors.
- **Optional links** — emailing feedback or opening the donation link shares data directly with those third parties under their own terms.

## Analytics

- **No analytics, tracking, or crash-reporting SDKs** are bundled.
- The "reading statistics" shown in Settings (articles opened/completed, minutes read) are derived **locally** from `LibraryStore`. They are never transmitted and are kept separate from any aggregate counters.

## External services contacted

| Service | Purpose | When |
|---------|---------|------|
| Mirror sources (`MirrorCatalog.defaults`) | Fetch article content for the URL you opened | On article open / retry |
| Email / Buy Me a Coffee (links) | Feedback and optional donations | Only when you explicitly use them |

## How cached articles are stored

- Offline articles are stored as **cleaned HTML strings** in `LibraryStore`, capped at a 64 MB soft budget with oldest-entry eviction (`LibraryStore.saveArticle`).
- Large HTML is never held in reactive controller state; it is only read back into the WebView when an offline copy is opened.

## How users can clear local data

- **Settings → Library & Storage** provides one-tap "Delete" for saved articles and recent searches.
- Library lists support per-item removal (swipe) and "Clear" dialogs.
- Uninstalling / clearing app data removes everything on all platforms.

## Logging

- `AppLog` is a lightweight, level-based logger (debug/info/warning/error). It logs feature context and messages — **not** full article URLs or content — and is not shipped to any remote sink.

## Secrecy

- No API keys or secrets are compiled into the app; mirrors are public endpoints fetched over HTTPS.