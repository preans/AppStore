#!/usr/bin/env bash
#
# ship.sh — build an app and publish it to the store
#
# Usage:
#   scripts/ship.sh <app-slug> [--version 1.2.3] [--notes "what changed"]
#
# Expects:
#   apps/<app-slug>/<app-slug>.xcodeproj   (or .xcworkspace)
#   The Xcode scheme named <app-slug>.
#
# Result:
#   ipa/<app-slug>-<version>.ipa  (unsigned .ipa, signed by AltStore on-device)
#   apps.json updated with a new version entry prepended to versions[]
#   ready for `git add . && git commit -m "ship <slug> <version>" && git push`

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- args ---------------------------------------------------------------------
SLUG="${1:-}"
[[ -z "$SLUG" ]] && { echo "usage: $0 <app-slug> [--version X.Y.Z] [--notes '...']" >&2; exit 1; }
shift

VERSION=""
NOTES="New build."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --notes)   NOTES="$2";   shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

APP_DIR="apps/$SLUG"
[[ -d "$APP_DIR" ]] || { echo "no project at $APP_DIR" >&2; exit 1; }

# --- locate xcode project -----------------------------------------------------
if   [[ -d "$APP_DIR/$SLUG.xcworkspace" ]]; then PROJ_FLAG=(-workspace "$APP_DIR/$SLUG.xcworkspace")
elif [[ -d "$APP_DIR/$SLUG.xcodeproj"   ]]; then PROJ_FLAG=(-project   "$APP_DIR/$SLUG.xcodeproj")
else echo "no .xcodeproj or .xcworkspace inside $APP_DIR named $SLUG" >&2; exit 1
fi

# --- read version from Info.plist if not given --------------------------------
if [[ -z "$VERSION" ]]; then
  # -L: APP_DIR may be a symlink to a project living outside this repo
  PLIST="$(find -L "$APP_DIR" -name Info.plist -not -path '*/.build/*' -not -path '*/build/*' | head -1)"
  if [[ -n "$PLIST" ]]; then
    VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null || true)"
  fi
fi
[[ -z "$VERSION" ]] && VERSION="0.0.$(date +%s)"

DATE="$(date +%F)"
BUILD_DIR="$(mktemp -d)"
ARCHIVE="$BUILD_DIR/$SLUG.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
IPA_OUT="ipa/${SLUG}-${VERSION}.ipa"
mkdir -p ipa

echo "==> archiving $SLUG ($VERSION)"
xcodebuild \
  "${PROJ_FLAG[@]}" \
  -scheme "$SLUG" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  archive >/tmp/ship-$SLUG.log 2>&1 || { tail -50 /tmp/ship-$SLUG.log; exit 1; }

# --- repackage .xcarchive into an unsigned .ipa -------------------------------
# (the standard export path requires signing; AltStore signs on install, so we
# build the Payload/ structure manually.)
echo "==> packaging unsigned .ipa"
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
APP_BUNDLE="$(find "$ARCHIVE/Products/Applications" -maxdepth 1 -name '*.app' | head -1)"
[[ -d "$APP_BUNDLE" ]] || { echo "no .app inside archive" >&2; exit 1; }
cp -R "$APP_BUNDLE" "$PAYLOAD_DIR/"
( cd "$BUILD_DIR" && zip -qry "$REPO_ROOT/$IPA_OUT" Payload )

SIZE="$(stat -f%z "$IPA_OUT")"
SHA="$(shasum -a 256 "$IPA_OUT" | awk '{print $1}')"

# --- read bundle id + min OS from the built app -------------------------------
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_BUNDLE/Info.plist")"
MIN_OS="$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$APP_BUNDLE/Info.plist" 2>/dev/null || echo '16.0')"

# --- compute the download URL relative to the GitHub Pages host ---------------
SOURCE_BASE="$(jq -r '.website // ""' apps.json | sed 's:/*$::')"
[[ -z "$SOURCE_BASE" ]] && { echo "set .website in apps.json to your GitHub Pages URL" >&2; exit 1; }
DOWNLOAD_URL="$SOURCE_BASE/$IPA_OUT"

# --- splice a new version entry to the top of versions[] ---------------------
echo "==> updating apps.json"
TMP="$(mktemp)"
jq --arg id "$BUNDLE_ID" \
   --arg v "$VERSION" \
   --arg d "$DATE" \
   --arg notes "$NOTES" \
   --arg url "$DOWNLOAD_URL" \
   --argjson size "$SIZE" \
   --arg sha "$SHA" \
   --arg minos "$MIN_OS" \
   '
    .apps |= map(
      if .bundleIdentifier == $id then
        .versions = ([{
          version: $v, date: $d, localizedDescription: $notes,
          downloadURL: $url, size: $size, sha256: $sha, minOSVersion: $minos
        }] + (.versions // []))
      else . end
    )
   ' apps.json > "$TMP" && mv "$TMP" apps.json

echo
echo "shipped $SLUG $VERSION"
echo "  ipa:  $IPA_OUT  ($SIZE bytes)"
echo "  sha:  $SHA"
echo
echo "next:"
echo "  git add . && git commit -m 'ship $SLUG $VERSION' && git push"
