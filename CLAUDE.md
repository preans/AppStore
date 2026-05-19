# Instructions for Claude Code working in this repo

This repo is Paul's personal iOS app store. When Paul asks you to build an app, the deliverable is a working iOS app published into this catalog — not a one-off Xcode project on disk.

## Mental model

- `apps/<slug>/` — the source for one app. One subfolder per app. Slug is lowercase, hyphenated, matches the Xcode scheme name.
- `ipa/` — built `.ipa` files. Each app version produces one file: `ipa/<slug>-<version>.ipa`.
- `apps.json` — the catalog AltStore reads. **You update this** when you ship a new app or a new version. The `scripts/ship.sh` helper does most of the work.
- `index.html` — the storefront page. You don't normally touch this; it renders from `apps.json`.
- `icons/` — app icons referenced from `apps.json` (`iconURL` field).

## When Paul says "build me an app that does X"

1. **Pick a slug.** Lowercase, hyphenated, short. e.g. "workout tracker" → `workout-tracker`. Confirm with Paul if you're not sure.
2. **Scaffold the Xcode project** under `apps/<slug>/`. Use SwiftUI. Use a bundle identifier of the form `com.paulreaney.<slug>` (no hyphens — convert to camelCase for the bundle ID if needed). Set the scheme name to `<slug>` so `ship.sh` can find it.
3. **Add a placeholder catalog entry** to `apps.json` in `apps[]` with the right `bundleIdentifier`, `name`, `subtitle`, `category`. Leave `versions: []` for now — `ship.sh` will populate it.
4. **Add an app icon** at `icons/<slug>.png` (1024×1024 ideally; generate something reasonable if Paul doesn't provide one). Set `iconURL` to `https://paulreaney.github.io/AppStore/icons/<slug>.png`.
5. **Build and ship:**
   ```
   scripts/ship.sh <slug> --version 0.1.0 --notes "Initial release."
   ```
   This produces an unsigned `.ipa` (AltStore signs it on-device with Paul's free Apple ID) and updates `apps.json`.
6. **Commit and push.** Then tell Paul the app will appear in AltStore on his phone within ~30 seconds — he taps "Get" to install.

## Constraints to honor

- **Free Apple ID.** Don't add entitlements that require a paid developer account (no Push Notifications, no iCloud, no App Groups, no Sign in with Apple). If Paul asks for a feature that needs one of these, surface the trade-off before building.
- **Bundle identifier prefix.** Always `com.paulreaney.<something>`. The free Apple ID's 3-app limit is per bundle-ID prefix on device, so don't churn the prefix.
- **iOS deployment target.** Default to iOS 16.0 unless Paul has a reason to go lower.
- **No CocoaPods, no external dependency managers unless asked.** Swift Package Manager is fine.
- **Keep apps small and single-purpose.** This is a personal store, not the App Store. One feature, well done, beats a 12-screen sprawl.

## When Paul says "update <app> to do Y"

1. Edit the source under `apps/<slug>/`.
2. Bump `CFBundleShortVersionString` in Info.plist (semver — patch for tweaks, minor for new features).
3. Run `scripts/ship.sh <slug> --notes "what changed"`. It picks up the new version from Info.plist automatically.
4. Commit + push.

## Things you should *not* do without asking

- Don't change `apps.json` fields like `name`, `subtitle`, `tintColor` at the top level (those are the store's branding, not any one app's).
- Don't delete `.ipa` files from `ipa/` — older versions are kept for rollback.
- Don't try to sign the `.ipa` yourself. AltStore handles signing on-device. The build is intentionally unsigned (`CODE_SIGNING_ALLOWED=NO`).
- Don't add a new top-level dependency (Swift package, frameworks) without flagging it.

## If something fails

- `xcodebuild` errors are logged to `/tmp/ship-<slug>.log`. Read the last 50 lines first.
- If `jq` says `apps.json` is invalid after a ship, restore it from `git checkout -- apps.json` and try again.
- If AltStore on Paul's phone can't see the new version, the usual cause is GitHub Pages not having rebuilt yet (give it 30–60 seconds) or `apps.json` having the wrong `downloadURL` (must match `website` + path).
