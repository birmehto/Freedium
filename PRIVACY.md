# Privacy

Freedium is built around one principle: **your reading stays on your device.**

This document is the developer-facing privacy model. The end-user version is in [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## What data is stored locally

All user data lives on-device in a local SQLite database (managed by Drift) and is split across four stores:

| Store | Data |
|-------|------|
| `PreferencesStore` | Theme mode (system/light/dark), reader settings (reader theme, font family, font size), preferred mirror, auto-fallback flag |
| `LibraryStore` | Favorites (title, URL, author, domain) and cached article metadata (title, author, publication, word count, reading time, published date) |
| `ArticleCacheStore` | The text of articles you read, for offline reading, with the URL it belongs to and its metadata |
| `ReadingProgressStore` | How far you got through each article (scroll position and fraction read) and when |

Clearing the app data (or uninstalling) wipes everything.

## What data leaves the device

- **Article URLs** — the only data sent is the article URL you choose to open, sent to the selected mirror service to fetch the page. The mirror's own terms and privacy practices apply to that request. Freedium is independent and not affiliated with the mirrors.
- **Optional links** — emailing feedback or opening the donation link shares data directly with those third parties under their own terms.
- **Optional rewarded ads** — no ad is shown unless the user chooses to watch one. To avoid a wait, the app warms the ad SDK up at startup and requests a single rewarded ad; that request goes to Google Mobile Ads, may include the advertising identifier, and is the only ad traffic unless a video is actually watched.

## Analytics

- **No analytics, tracking, or crash-reporting SDKs** are bundled, and the app collects no usage statistics of its own.
- The only ad SDK is Google Mobile Ads. No ad is ever shown unless the user asks for one, though the app warms the SDK up at startup — initializing it and requesting a single rewarded ad — so the video is ready without a wait. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## External services contacted

| Service | Purpose | When |
|---------|---------|------|
| Mirror sources (`MirrorCatalog.defaults`) | Fetch article content for the URL you opened | On article open / retry |
| Google Mobile Ads | Optional rewarded video | Only when the user chooses "Watch a short ad" |
| Email / Buy Me a Coffee (links) | Feedback and optional donations | Only when you explicitly use them |

## How article content is handled

- Article text is stored **on the device only**, and only for articles you favorite, so a favorite can be reopened without a connection. Nothing is stored just because you read something, and nothing is sent anywhere to store it.
- The offline cache is capped (24 MB in total, 2 MB per article). Past the cap the oldest saved articles are dropped automatically, except favorites, which are never evicted.
- Metadata is cached separately, so the library and "Continue reading" can render without refetching.
- Removing a favorite also removes its stored copy, from the article itself or from your library.

## How users can clear local data

- Favorites support per-item removal, and entries can be deleted individually. Removing one also drops the article text stored for it.
- Uninstalling or clearing app data removes everything. Android backups are disabled (`android:allowBackup="false"` plus explicit data-extraction rules), so data does not leave the device through cloud backup or device transfer.

## Logging

- `AppLog` is a lightweight, level-based logger (debug/info/warning/error). It logs feature context and messages — **not** full article URLs or content — and is not shipped to any remote sink.

## Secrecy

- No API keys or secrets are compiled into the app; mirrors are public endpoints fetched over HTTPS.
- The one secret is the AdMob configuration (application id and rewarded unit). It is **not** committed: `envied` reads the ids from a git-ignored `.env` and emits an obfuscated `env.g.dart`, and the Android build injects the application id into the manifest at build time. Without a `.env`, Google's public test ids are used.