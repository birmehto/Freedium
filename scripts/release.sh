#!/usr/bin/env bash
#
# Freedium Android release script.
#
# Builds all Android APK variants (universal + per-ABI splits), then creates
# a GitHub release tagged with the version from pubspec.yaml and uploads every
# APK as a release asset.
#
# Usage:
#   ./scripts/release.sh            # auto version from pubspec.yaml (assumes tag exists)
#   ./scripts/release.sh v1.2.3     # explicit tag/version
#
# Prerequisites:
#   - Flutter SDK on PATH
#   - GitHub CLI (gh) authenticated
#   - android/key.properties with a valid signing config
#   - git branch pushed (release created from current HEAD, tags are NOT pushed)
#
# Requires network to publish to GitHub.

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION_TAG="${1:-}"
if [[ -z "$VERSION_TAG" ]]; then
  VERSION_TAG="v$(grep '^version:' pubspec.yaml | sed 's/^version: *//' | cut -d'+' -f1)"
fi

DIST_DIR="$REPO_ROOT/release-apks"
NOTES_FILE="$REPO_ROOT/RELEASE_NOTES.md"

# ── Preflight ───────────────────────────────────────────────────────────────
command -v flutter >/dev/null 2>&1 || { echo "ERROR: flutter not found on PATH" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "ERROR: gh (GitHub CLI) not found on PATH" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: gh is not authenticated" >&2; exit 1; }
[[ -f "$REPO_ROOT/android/key.properties" ]] || { echo "ERROR: android/key.properties missing" >&2; exit 1; }
[[ -d "$REPO_ROOT/android" ]] || { echo "ERROR: android/ directory missing" >&2; exit 1; }

# ── Build stale branch guard ────────────────────────────────────────────────
if gh release view "$VERSION_TAG" >/dev/null 2>&1; then
  echo "NOTE: release '$VERSION_TAG' already exists — APKs will be added to it."
fi

# ── Build APKs ──────────────────────────────────────────────────────────────
echo "==> Building universal APK ($VERSION_TAG)"
flutter build apk --release

echo "==> Building split APKs ($VERSION_TAG)"
flutter build apk --release --split-per-abi

# ── Collect artifacts ───────────────────────────────────────────────────────
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

cp build/app/outputs/flutter-apk/app-release.apk \
   "$DIST_DIR/Freedium-$VERSION_TAG-universal.apk"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
   "$DIST_DIR/Freedium-$VERSION_TAG-arm64-v8a.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
   "$DIST_DIR/Freedium-$VERSION_TAG-armeabi-v7a.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
   "$DIST_DIR/Freedium-$VERSION_TAG-x86_64.apk"

echo "==> APKs prepared:"
ls -lh "$DIST_DIR"

# ── Publish to GitHub ───────────────────────────────────────────────────────
if gh release view "$VERSION_TAG" >/dev/null 2>&1; then
  echo "==> Uploading APKs to existing release '$VERSION_TAG'"
  gh release upload "$VERSION_TAG" "$DIST_DIR"/*.apk --clobber
else
  echo "==> Creating release '$VERSION_TAG'"
  NOTES_ARG=()
  if [[ -f "$NOTES_FILE" ]]; then
    NOTES_ARG=(--notes-file "$NOTES_FILE")
  fi
  gh release create "$VERSION_TAG" \
    --title "$VERSION_TAG" \
    "${NOTES_ARG[@]}" \
    "$DIST_DIR"/*.apk
fi

echo
echo "==> Done. Release: https://github.com/birmehto/Freedium/releases/tag/$VERSION_TAG"