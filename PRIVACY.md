# Privacy

Freedium is built around one principle: **your reading stays on your device.**

This document is the developer-facing privacy model. The end-user version is in [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## What data is stored locally

All user data lives on-device in a local SQLite database (managed by Drift) and is split across three stores:

| Store | Data |
|-------|------|
| `PreferencesStore` | Theme mode (system/light/dark), reader settings (reader theme, font family, font size), preferred mirror, auto-fallback flag |
| `LibraryStore` | Favorites (title, URL, author, domain) and cached article metadata (title, author, publication, word count, reading time, published date) |
| `AccountStore` | The optional Medium account: session cookies and the cached profile (handle, name, bio, avatar URL, follower and post counts) |

Clearing the app data (or uninstalling) wipes everything.

## The optional Medium account

Medium publishes no API for signing a reader in or reading their profile, so the account feature works the only way it can: the reader signs in on **Medium's own sign-in page**, inside an in-app WebView.

- **Freedium never sees, requests, stores or transmits a password.** The credentials are typed into Medium's page and go straight to Medium.
- What is kept is the **session cookie Medium itself issues** on sign-in (`sid`, `uid`, `token` and the CSRF cookies that go with them), stored in the local database and re-injected into the WebView cookie jar on the next launch. This is the only credential-like value in the app, and it is never logged.
- Analytics and advertising cookies are dropped rather than persisted — they say nothing about the session and would only widen the stored footprint.
- Signing out deletes the cookies from the WebView jar, clears the saved session and deletes the cached profile. It does not touch the library, theme or mirrors.
- The account is **entirely optional**: nothing else in the app depends on it, and the app is fully functional signed out.
- `AccountStore` values are stored in the same SQLite database as everything else rather than in platform key storage, so the session is protected by the same controls as the rest of the app's data: no Android cloud backup, no device transfer, and no remote backup of any kind.

## What data leaves the device

- **Article URLs** — the only data sent is the article URL you choose to open, sent to the selected mirror service to fetch the page. The mirror's own terms and privacy practices apply to that request. Freedium is independent and not affiliated with the mirrors.
- **Medium, when you sign in** — signing in, refreshing your profile, and signing out all contact `medium.com` directly, under Medium's own terms and privacy policy. Your Medium session cookie travels to Medium and nowhere else. Freedium operates no server of its own, so none of this passes through us.
- **Optional links** — emailing feedback or opening the donation link shares data directly with those third parties under their own terms.

## Analytics

- **No analytics, tracking, or crash-reporting SDKs** are bundled, and the app collects no usage statistics of its own.
- Signing in to Medium runs Medium's own pages in the WebView, which means Medium's own scripts behave as they would in a browser. That is inherent to signing in to Medium at all, and is the same for any client that does it.

## External services contacted

| Service | Purpose | When |
|---------|---------|------|
| Mirror sources (`MirrorCatalog.defaults`) | Fetch article content for the URL you opened | On article open / retry |
| Medium (`medium.com` and its sign-in identity providers) | Sign in, and read your own public profile | Only if you choose to sign in, refresh, or sign out |
| Email / Buy Me a Coffee (links) | Feedback and optional donations | Only when you explicitly use them |

## How article content is handled

- Article HTML is **never stored**. The reader loads each article over the network into the WebView and discards it on exit.
- Only lightweight metadata is cached, so the favorites list can render without refetching. Clearing the library or the app data removes it.

## How users can clear local data

- Favorites support per-item removal, and entries can be deleted individually.
- Signing out of Medium removes the session cookies and the cached profile.
- Uninstalling or clearing app data removes everything. Android backups are disabled (`android:allowBackup="false"` plus explicit data-extraction rules), so data does not leave the device through cloud backup or device transfer.

## Logging

- `AppLog` is a lightweight, level-based logger (debug/info/warning/error). It logs feature context and messages — **not** full article URLs, content, or session cookies — and is not shipped to any remote sink.

## Secrecy

- No API keys or secrets are compiled into the app; mirrors are public endpoints fetched over HTTPS.