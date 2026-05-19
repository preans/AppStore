# Paul's Personal App Store

A self-hosted iOS app store. You build apps on your Mac (with Claude Code driving Xcode), publish their `.ipa` files to this repo, and the catalog is served as a [GitHub Pages](https://pages.github.com/) site that the [AltStore](https://altstore.io/) iOS app reads as a "source." Your iPhone — and any friend who adds your source — sees the apps appear and can install them with one tap.

This is the "Naval personal app store" pattern, but with a sharing layer bolted on for friends and family.

## How it works

```
┌─────────────────────────┐         ┌──────────────────────────┐
│  You (on your Mac)      │         │  Your iPhone             │
│                         │         │                          │
│  "Claude, build me a    │         │   ┌──────────────────┐   │
│   workout tracker."     │         │   │   AltStore app   │   │
│                         │         │   │                  │   │
│           │             │         │   │  Source URL ───┐ │   │
│           ▼             │         │   └────────────────┼─┘   │
│  Claude Code            │         │                    │     │
│      │                  │         └────────────────────┼─────┘
│      ▼                  │                              │
│  Xcode build            │                              │
│      │                  │                              │
│      ▼                  │         ┌────────────────────▼─────┐
│  .ipa file              │         │  GitHub Pages            │
│      │                  │         │                          │
│      ▼                  │  push   │  • index.html (storefront)│
│  ship.sh ──────────────────────► │  • apps.json (catalog)   │
│                         │         │  • ipa/*.ipa (downloads) │
└─────────────────────────┘         └──────────────────────────┘
```

The user describes the app in plain English. Claude Code generates the Swift/SwiftUI project, builds it through `xcodebuild`, drops the `.ipa` into the `ipa/` folder, appends a version entry to `apps.json`, and pushes to GitHub. GitHub Pages serves the catalog. On your phone, AltStore polls your source URL, sees the new version, and lets you install it.

## What's in this repo

| Path | What it is |
|---|---|
| `apps.json` | The AltStore source — the catalog AltStore reads on the iPhone |
| `index.html` | The storefront webpage served at your GitHub Pages URL |
| `apps/` | One subfolder per app — the Xcode project source lives here |
| `ipa/` | Built `.ipa` files (the actual installable bundles) |
| `icons/` | App icons referenced from `apps.json` |
| `scripts/ship.sh` | Build + publish a new app version |
| `CLAUDE.md` | Instructions Claude Code reads when working in this repo |
| `SETUP.md` | First-time setup walkthrough (AltStore, AltServer, GitHub Pages) |

## Quickstart

1. Follow [`SETUP.md`](./SETUP.md) once: install AltStore + AltServer on the Mac, pair your iPhone, enable GitHub Pages, add the source URL on your phone.
2. To make a new app, in this repo run:

   ```
   claude
   > build me a [describe the app]
   ```

   Claude Code will read [`CLAUDE.md`](./CLAUDE.md), scaffold the Xcode project under `apps/<name>/`, build it, and update `apps.json`.
3. Push the commit. Within ~30 seconds AltStore on your phone shows the new app or version. Tap install.

## The honest caveats

**Free Apple ID limits.** You picked the free path. That means:

- Installed apps expire after **7 days** and must be re-signed by AltServer running on your Mac while the phone is on the same Wi-Fi.
- Each device can have **at most 3 apps** signed by a free Apple ID at a time.
- Friends who want to install your apps need their *own* free Apple ID + their *own* AltServer running on a Mac/PC. The catalog is shared; the signing is per-person.

**The $99/year upgrade.** If/when you join the Apple Developer Program:

- Signed apps stay valid for **1 year** instead of 7 days.
- No 3-app limit.
- You can pre-sign `.ipa`s yourself so friends don't need AltServer at all (they just install via AltStore from your source).
- Same repo, same scaffold — only `ship.sh` changes (it starts signing with your team certificate instead of producing an unsigned `.ipa`).

**Apple's hard limit.** Even with `$99/year`, Apple caps "ad-hoc" distribution at **100 devices per device family per year**. For a friends-and-family store that's plenty. To go wider than that, you'd need the EU's AltStore PAL marketplace path or TestFlight — see the discussion in chat for those.

## Why not just use TestFlight?

TestFlight is Apple's storefront, not yours. You don't get a custom catalog page, you can't host arbitrary metadata, and every build needs review (lightweight but still review). The AltStore-source path means *you* own the distribution surface — same shape as Naval's personal app store, just with a sharing layer.
