# Architecture

Freedium is a Flutter reading app that turns Medium article links into clean, paywall-free reading experiences. It keeps a pragmatic **GetX-based architecture** organized by feature.

## Overview

```text
main.dart
  └─ app.dart                     GetMaterialApp, theme wiring
      └─ core/routes/app_pages.dart   routes + bindings
          └─ AppShell                 responsive Home / Library / Settings shell
              └─ feature pages (GetView)
```

## Directory layout

```text
lib/
├── app.dart                        WidgetsBinding / app root
├── main.dart                       Startup, storage init, services
├── core/
│   ├── config/                     MirrorSource + MirrorCatalog
│   ├── constants/                  AppConstants, ReaderTheme (CSS + reader JS)
│   ├── errors/                     AppException
│   ├── extensions/                 BuildContext helpers
│   ├── network/                    ArticleUrl (canonicalization), ArticleResolver
│   ├── routes/                     AppRoutes, AppPages (routes + bindings)
│   ├── services/                   StorageService facade, ThemeService,
│   │                               ShareIntentService, ClipboardService
│   ├── storage/                    KeyValueStore, PreferencesStore, LibraryStore
│   ├── utils/                      AppLog
│   └── widgets/                    Shared App* widgets (AppButton, AppEmpty, …)
└── features/
    ├── article/                    Reader: controller, webview, metadata models
    ├── favorites/                  Favorites list + model
    ├── home/                       URL entry screen
    └── settings/                   Settings: theme, reader, sources
```

Each feature owns its `controllers/`, `models/`, `views/`, `widgets/` and (where needed) `bindings/`. Reusable cross-feature UI lives in `core/widgets/`.

## Conventions

- **Controllers** (`GetxController`) own UI state and orchestrate services. Views stay thin (`GetView<XController>`).
- **Services** (`GetxService`) wrap external operations: persistence, sharing intents, clipboard, theme.
- **Models** are plain Dart classes with `fromJson`/`toJson`/`copyWith`. Serialization stays out of controllers.
- **Bindings** wire dependencies via `Get.put` / `Get.lazyPut`; routes register the bindings they need.
- **Reactive state** is exposed as `Rx<T>` getters on controllers; pages subscribe with `Obx`.
- Business logic is kept testable: dependencies are injected via constructors, and tests substitute in-memory implementations.

## The reader pipeline

```text
Bare link / shared URL
   ↓ ArticleUrl.canonicalize()      strip tracking params, normalize host
   ↓ ArticleResolver.resolve()      pick preferred → healthy mirror URL
   ↓ InAppWebView loads mirror
   ↓ onPageStarted / onProgress     loadingProgress, metadata markers
   ↓ ReaderTheme.earlyStyleInjector injects reader CSS pre-paint
   ↓ onPageFinished
       ├─ ReaderTheme.extractMetaJs → ArticleMeta (title/author/publication/…)
       ├─ restore scroll position   LibraryStore.getReadingProgress
       ├─ layout metrics            content height for % progress
       └─ metadata cached          LibraryStore.cacheMeta
```

Reader preferences from `PreferencesStore.readerSettings` drive `ReaderTheme.getCss`, which is JSON-encoded before injection so reader CSS can never break out of the script string. Article HTML is never stored or held in reactive state; the WebView always loads over the network and only lightweight metadata is cached in `LibraryStore`.

## Mirror system

- `MirrorSource` — backend definition (id, name, URL template) plus mutable health: availability, consecutive/total failures, last success/attempt, response time.
- `MirrorCatalog.defaults` — the known mirrors (Freedium mirror, Textise text fallback).
- `ArticleResolver` — orders candidates by preference + health, resolves URLs, tracks success/failure, and returns the next fallback. `autoFallback` is a user setting persisted in `PreferencesStore`.
- Health state is in-memory only (per resolver instance); failures do not leak user article URLs.

## Storage

Two focused stores behind a thin `KeyValueStore` interface:

```text
StorageService (owner, GetxService)
 ├── preferences  → PreferencesStore   light device settings
 │                    theme mode, reader settings,
 │                    preferred mirror, auto fallback
 └── library      → LibraryStore       content data
                      favorites, cached article metadata
```

`DriftKeyValueStore` is the production backend (a single JSON `kv` table in a SQLite database via Drift, kept in sync with an in-memory cache for synchronous reads); `MemoryKeyValueStore` is used in tests. Writes are serialized through an internal queue so overlapping updates cannot interleave, and `StorageService.withStore` injects an in-memory store for tests. `LibraryStore.favorites` is the single reactive list of record — no duplicate copy is kept in a controller. Storage keys are stable (`favorites_list`, `cached_meta`) so existing installs keep their data.

## Theming

- `ThemeService` exposes an effective dark-mode flag plus a full `ThemeMode` (system/light/dark) for the app.
- Reader appearance is separate from the app theme: `ReaderThemeMode` (system/light/dark/sepia/oled) + typography/width settings render purely inside the WebView via injected CSS.

## Testing

- Unit tests for models, URL parsing, resolver, and stores (`test/features/...`, `test/core/...`).
- Controller/widget tests use mock services (`MockStorageService` overrides the facade getters).
- Run checks locally:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Release process

See `CONTRIBUTING.md` and `scripts/release.sh`. A tag `vX.Y.Z` triggers the release script which builds the platform artifacts and publishes the GitHub release; CI runs format + analyze + test on every pull request.