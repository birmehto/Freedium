# Publishing Freedium on F-Droid

F-Droid has no upload console. Apps are added by opening a merge request against
the [`fdroiddata`](https://gitlab.com/fdroid/fdroiddata) repository on GitLab,
where a maintainer reviews the recipe and the build server rebuilds the app from
source. This guide covers everything on our side of that process.

The app repository contains:

- `fastlane/metadata/android/en-US/` — title, descriptions, changelog, icon and
  screenshots. F-Droid reads these directly from the source repository.
- `fdroid/com.bir.freedium.yml` — a copy-ready recipe for `fdroiddata`.

## 1. Publish a tagged release

F-Droid builds a specific commit, not a branch head. The recipe points at the
tag `v1.3.0`.

```bash
git checkout main
git pull
git tag -a v1.3.0 -m "Freedium 1.3.0"
git push origin v1.3.0
```

Make sure `pubspec.yaml` says `version: 1.3.0+7` and that the tag points at that
commit. If you use a different commit, change `commit:` in the recipe to match.

Before tagging, verify the build locally:

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build apk --release
```

The release build works without `android/key.properties`: Gradle falls back to
the debug key and F-Droid replaces the signature with its own.

## 2. Fork `fdroiddata`

On GitLab, open <https://gitlab.com/fdroid/fdroiddata> and click **Fork**, or use
the CLI:

```bash
glab repo fork fdroid/fdroiddata --clone
cd fdroiddata
git checkout -b com.bir.freedium
```

## 3. Add the recipe

```bash
cp /path/to/Freedium/fdroid/com.bir.freedium.yml metadata/com.bir.freedium.yml
git add metadata/com.bir.freedium.yml
git commit -m "New app: com.bir.freedium (Freedium)"
```

If you have `fdroidserver` installed, validate the metadata before pushing:

```bash
fdroid lint com.bir.freedium
```

At minimum, confirm the YAML parses:

```bash
python3 -c "import yaml; yaml.safe_load(open('metadata/com.bir.freedium.yml'))"
```

## 4. Open the merge request

```bash
git push -o merge_request.create \
  -o merge_request.title="New app: com.bir.freedium (Freedium)" \
  -o merge_request.label="new app"
```

Without `glab`, push the branch and use **Merge requests → New merge request**
in the GitLab web UI. In the description, link the source repository, the tag
and the release notes, and state plainly that the app uses public third-party
mirrors.

## 5. What to expect

- A build server checks out the tag, installs the Flutter srclib and rebuilds
  the APK. If the build fails, the merge request gets a log with the error.
- A maintainer reviews the metadata, the license, the anti-features and the
  screenshots. Questions are posted on the MR — reply there.
- Reviews can take weeks; F-Droid is volunteer-run. Do not open a second MR for
  the same app.
- Once merged, the app appears in the F-Droid repository with the next index
  update. Updates are submitted by changing `versionName`, `versionCode` and
  `commit` in the same metadata file.

## Before you submit: read this

Freedium fetches Medium stories through public third-party mirrors. That is why
the recipe declares `NonFreeNet` and `TetheredNet`: the app's own code is MIT
licensed, but reading an article depends on external services the project does
not control. F-Droid's inclusion policy also considers copyright and
paywall-circumvention tools; a maintainer may decline the app regardless of how
clean the build is. Declaring the anti-features honestly is the best thing we
can do — do not remove them to make the review easier.

If the app is declined, the alternative is an **RFP** (Request For Packaging)
at <https://gitlab.com/fdroid/rfp>, which asks the community to decide whether
to package it. Either way, keep the MR or RFP open and respond to feedback.
