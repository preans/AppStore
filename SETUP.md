# First-time setup

You only do this once. After that, shipping new apps is `scripts/ship.sh ...` + `git push`.

## 1. Prerequisites on your Mac

- macOS with **Xcode** installed (you have this).
- **Homebrew**, then: `brew install jq`. (`ship.sh` uses `jq` to edit `apps.json`.)
- A free **Apple ID** signed into Xcode → Settings → Accounts.

## 2. Push this repo to GitHub

From this folder:

```
git init
git add .
git commit -m "Initial app store scaffold"
gh repo create AppStore --public --source=. --remote=origin --push
```

(Or do the equivalent manually in github.com if you don't use `gh`.)

The repo must be **public** for GitHub Pages to serve it on the free plan, and so AltStore on any friend's phone can read `apps.json` without auth.

## 3. Turn on GitHub Pages

On github.com → your repo → **Settings → Pages**:

- **Source:** Deploy from a branch
- **Branch:** `main`, folder `/ (root)`
- Save.

Within a minute or two your store will be live at:

```
https://<your-github-username>.github.io/AppStore/
```

Open that URL in a browser to confirm the storefront renders. The "Add to AltStore" bar at the top should show the URL of your `apps.json`.

## 4. One-time fix: update `apps.json` for your username

The scaffold assumes `preans.github.io`. If your GitHub username is different, do a find-and-replace in `apps.json` and `CLAUDE.md`:

```
preans.github.io  →  <your-username>.github.io
com.preans.       →  com.<your-username>.
```

Commit + push.

## 5. Install AltServer on your Mac

[AltServer for Mac](https://altstore.io/) — download the free macOS app from altstore.io. Launch it; you'll see a small diamond icon in the menu bar. Keep it running whenever you want to install or re-sign apps on your iPhone.

## 6. Install AltStore on your iPhone

1. Plug your iPhone into the Mac with a cable (first time only). Trust the computer when prompted.
2. On the Mac, click the AltServer menu-bar icon → **Install AltStore** → pick your iPhone.
3. Enter your Apple ID and password when AltServer asks. (It's stored locally on your Mac, used to re-sign apps with your free certificate.)
4. AltStore appears on your iPhone home screen. The first time you open it, iOS will say "Untrusted Developer." Go to **Settings → General → VPN & Device Management** → find your Apple ID under "Developer App" → **Trust**.

## 7. Add your store as a source in AltStore

On your iPhone:

1. Open AltStore → **Browse** tab → **Sources** → **+** in the top-right.
2. Paste your source URL: `https://<your-username>.github.io/AppStore/apps.json`.
3. Add. Your store appears in the sources list.

(Or, on the storefront webpage from a desktop, copy the URL and add manually — `altstore://` deep links only work from the phone.)

## 8. Wi-Fi pairing for ongoing re-signing

So you don't have to plug your iPhone in every 7 days when apps expire:

- On the Mac, in Finder, click your iPhone in the sidebar → **General** tab → **"Show this iPhone when on Wi-Fi"** → check it → Apply.
- From then on, as long as AltServer is running on the Mac and the iPhone is on the same Wi-Fi network, AltStore can re-sign installed apps in the background.

## 9. Ship your first app

Back in this repo:

```
# Replace the Hello World placeholder with a real app.
claude
> build me a simple SwiftUI app called "Pet HQ Notes" — a one-screen
> notes app I use to jot quick notes about my dog
```

Claude reads `CLAUDE.md`, scaffolds `apps/pet-hq-notes/`, builds it, runs `scripts/ship.sh`, and tells you to push. Push, wait ~30 seconds, and the app appears in AltStore on your phone.

## Sharing with a friend (free Apple ID path)

For a friend to install your apps:

1. They install **AltServer** on their Mac/PC (yes, AltServer works on Windows too) and **AltStore** on their iPhone, signing in with their own free Apple ID.
2. They add your source URL inside their AltStore.
3. They tap "Get" on any of your apps. AltStore downloads the `.ipa` from your GitHub Pages, signs it with their Apple ID on their machine, and pushes it to their phone.

Yes — they need their own Mac/PC running AltServer for the weekly re-sign. This is the part the $99 developer account fixes (you can pre-sign `.ipa`s with your team cert and friends install without AltServer at all). If you upgrade later, only `ship.sh` changes.

## Troubleshooting

- **"Couldn't load apps.json" on the storefront.** GitHub Pages hasn't built yet (give it 60 seconds) or the repo isn't public.
- **AltStore says "App is not available."** The `downloadURL` in `apps.json` doesn't resolve. Open it in a browser — does the `.ipa` download? If 404, check the `website` field in `apps.json` matches your Pages URL exactly.
- **Install fails with "Could not connect to AltServer."** Mac asleep, AltServer quit, different Wi-Fi, or VPN interfering. Wake the Mac, confirm the menu-bar icon is there, same Wi-Fi.
- **"Maximum App ID limit reached."** Free Apple ID's 10-App-IDs-per-7-days limit. Wait it out or use the $99 program.
