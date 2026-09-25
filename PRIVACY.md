# Privacy

Freedium is built around one principle: **your reading stays on your device.**

This document is the developer-facing privacy model. The end-user version is in [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## What data is stored locally

All user data lives on-device in a local SQLite database (managed by Drift) and is split across two stores:

| Store | Data |
|-------|------|
| `PreferencesStore` | Theme mode (system/light/dark), reader settings (reader theme, font family, font size), preferred mirror, auto-fallback flag |
| `LibraryStore` | Favorites (title, URL, author, domain) and cached article metadata (title, author, publication, word count, reading time, published date) |

Clearing the app data (or uninstalling) wipes everything.

## What data leaves the device

- **Article URLs** — the only data sent is the article URL you choose to open, sent to the selected mirror service to fetch the page. The mirror's own terms and privacy practices apply to that request. Freedium is independent and not affiliated with the mirrors.
- **Optional links** — emailing feedback or opening the donation link shares data directly with those third parties under their own terms.

## Analytics

- **No analytics, tracking, or crash-reporting SDKs** are bundled, and the app collects no usage statistics of its own.

## External services contacted

| Service | Purpose | When |
|---------|---------|------|
| Mirror sources (`MirrorCatalog.defaults`) | Fetch article content for the URL you opened | On article open / retry |
| Email / Buy Me a Coffee (links) | Feedback and optional donations | Only when you explicitly use them |

## How article content is handled

- Article HTML is **never stored**. The reader loads each article over the network into the WebView and discards it on exit.
- Only lightweight metadata is cached, so the favorites list can render without refetching. Clearing the library or the app data removes it.

## How users can clear local data

- Favorites support per-item removal, and entries can be deleted individually.
- Uninstalling or clearing app data removes everything. Android backups are disabled (`android:allowBackup="false"` plus explicit data-extraction rules), so data does not leave the device through cloud backup or device transfer.

## Logging

- `AppLog` is a lightweight, level-based logger (debug/info/warning/error). It logs feature context and messages — **not** full article URLs or content — and is not shipped to any remote sink.

## Secrecy

- No API keys or secrets are compiled into the app; mirrors are public endpoints fetched over HTTPS.