# Contributing to Freedium

Thanks for helping out! This is a small, friendly, open-source project — code of conduct: be kind.

## Getting started

**Prerequisites:** Flutter `>= 3.44.0` + Dart `>= 3.13.0` (stable channel).

```bash
git clone https://github.com/birmehto/Freedium.git
cd Freedium
flutter pub get
dart run build_runner build   # generates Drift code
flutter run          # Android or Linux target
```

## Development workflow

1. Fork the repo and create a branch: `git checkout -b feat/my-idea`.
2. Make your changes.
3. Keep the quality bar green:
   ```bash
   dart format --set-exit-if-changed lib test
   flutter analyze
   flutter test
   ```
4. Commit with a concise, conventional message (e.g. `feat(reader): add sepia theme`).
5. Open a pull request against `main` and explain in the description **what** you changed and **why** — reference any related issue (e.g. `Closes #12`).

## Architecture

Before diving in, know the lay of the land. In short:

- GetX-based, feature-first folders (`features/<name>/{controllers,models,views,widgets,bindings}`).
- Shared UI lives in `core/widgets/`; external operations in `core/services/`.
- Storage is split into `PreferencesStore` (settings) and `LibraryStore` (content) behind a `KeyValueStore` interface; the production backend is a Drift/SQLite `kv` table, and tests use `MemoryKeyValueStore`. After touching a Drift table in `core/storage/app_database.dart`, regenerate code with `dart run build_runner build`.
- Reader theming and metadata are driven from `core/constants/reader_theme.dart`.

## Guidelines

- **State in controllers, not widgets.** Views are thin `GetView`s.
- **Keep business logic testable** — inject dependencies via constructors, avoid globals in hot paths.
- **Add tests** for new models, URL/store logic, and important widget flows. Run them with `flutter test`.
- **Match existing code style** — single quotes, trailing commas, M3 Expressive widgets (`M3E*`) from `material_3_expressive`, shared `App*` widgets for buttons/empty/error states.
- **Accessibility** — don't rely on icons alone; provide tooltips / semantic labels.
- **Privacy** — never log or transmit article URLs or user data beyond what is needed; nothing is ever sent to external telemetry, and the app ships no ad or analytics SDKs.

## Topic workflows

### Mirrors / sources

- Mirror definitions live in `lib/core/config/mirror_source.dart`. Resolver behavior is unit-tested in `test/features/network/article_resolver_test.dart` — add a case when you change fallback logic.

### Reader

- Reader CSS lives in `lib/core/constants/reader_theme.dart`; the controller in `lib/features/article/controllers/article_controller.dart`.
- Offline copies are written by one path only: `ArticleController.toggleFavorite`, because a favorite is a request to keep the article. Opening an article stores nothing. Extend `test/features/article/article_offline_test.dart` when you change it.
- A favorite must survive a body it cannot store, so `readArticleHtml` returning `null` is not a failed save. It is also the seam that suite replaces: the WebView is never built in tests.
- The one snackbar is `AppSnackbar.show` in `lib/core/widgets/app_snackbar.dart`: Flutter's own `SnackBar` presented through the nearest `ScaffoldMessenger`. It is the only path a transient message may take, and it resolves the messenger per call because a controller's `Get.context` can already be deactivated when the message fires — it stays silent rather than crash in that case.

### Storage

- Changing persistence touches `lib/core/storage/*`; extend the matching test in `test/features/library/library_store_test.dart`.

### Support

- The "Support Freedium" flow lives in `lib/features/support/`: a dialog whose single hand-off is `SupportController.buyCoffee`, which opens the donation page in the browser.

## Release process

Releases are manual via the tag-driven script:

```bash
./scripts/release.sh            # version from pubspec.yaml
./scripts/release.sh v1.2.3     # or pass the tag explicitly
```

The script builds the release artifacts and publishes the GitHub release via `gh`. Keep `CHANGELOG.md` and `RELEASE_NOTES.md` up to date around a release.

## Feedback

Bugs and requests: open an issue at <https://github.com/birmehto/Freedium/issues>. Email: birmehto@gmail.com.