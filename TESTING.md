# Install & Test on Your iPhone

A step-by-step guide for running OfflineQardioArm on a physical iPhone — aimed
at someone new to iOS development. Allow ~30 minutes the first time.

HealthKit does **not** work on the iOS Simulator. You need a real iPhone to
verify the Apple Health sync fix.

---

## 1. What you need

- **A Mac** running macOS Sonoma (14) or newer.
- **Xcode 16+** from the Mac App Store (free; ~10 GB download).
- **An Apple ID** — a free personal one works. Paid Apple Developer Program
  ($99/yr) is **not** required for side-loading onto your own device.
- **Your iPhone**, iOS 17 or newer, with a USB-C (or Lightning) cable.
- **The QardioArm cuff**, if you want to test a real reading end-to-end.

---

## 2. First-time Xcode setup (skip if you've done this before)

1. Open Xcode. Go to **Xcode → Settings → Accounts**.
2. Click the **+** in the bottom-left, choose **Apple ID**, and sign in.
3. Your Apple ID now appears as a "Personal Team" — this is what signs builds.

---

## 3. Enable Developer Mode on your iPhone

Required on iOS 16+ before any side-loaded app will launch.

1. Plug the iPhone into the Mac with the cable. Tap **Trust** if prompted.
2. On the iPhone: **Settings → Privacy & Security → Developer Mode → On**.
3. The iPhone reboots; after unlocking, tap **Turn On** to confirm.

---

## 4. Get the code

In Terminal:

```bash
git clone https://github.com/markuskreitzer/offline-qardio-app-ios.git
cd offline-qardio-app-ios
git checkout claude/fix-apple-health-sync-JeAeo
```

You should see these folders/files:

```
CLAUDE.md
LICENSE.md
PRIVACY.md
OfflineQardioArm/           <- all the app source lives here
```

> **Why no `.xcodeproj`?** The project file is intentionally not checked in
> (see `CLAUDE.md`). You need to create a new Xcode project locally and point
> it at the existing source, as described below.

---

## 5. Create the Xcode project

1. In Xcode, choose **File → New → Project…**
2. Select **iOS → App**, click **Next**.
3. Fill in:
   - **Product Name:** `OfflineQardioArm`
   - **Team:** your Personal Team (from step 2).
   - **Organization Identifier:** something unique like
     `com.yourname.offlineqardioarm`. Together with the product name this forms
     the **Bundle Identifier** — Apple requires this to be globally unique.
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we're not using Core Data)
   - **Include Tests:** unchecked
4. Click **Next**. When asked where to save, **save it outside the cloned
   repo** (e.g. your Desktop). We'll point this shell project at the repo's
   sources rather than copying them.
5. In the new project, in the Xcode file navigator (left sidebar), **delete**
   the auto-generated `ContentView.swift` and `<ProductName>App.swift`. When
   asked, choose **Move to Trash**.
6. Right-click the top-level `OfflineQardioArm` group in the sidebar and choose
   **Add Files to "OfflineQardioArm"…**
7. Navigate to the cloned repo's `OfflineQardioArm/` folder. Select everything
   inside it (`Controllers/`, `Models/`, `Views/`, `Assets.xcassets`,
   `ContentView.swift`, `OfflineQardioArmApp.swift`, `ToolbarLabelStyle.swift`,
   `Info.plist`, `OfflineQardioArm.entitlements`). In the dialog:
   - **Action:** "Create groups"
   - **Added folders:** "Create groups"
   - **Copy items if needed:** **unchecked** (so edits track the git repo)
   - **Add to targets:** check the app target.
8. Click **Add**.

---

## 6. Wire up Info.plist and entitlements

Xcode 15+ auto-generates an `Info.plist` from build settings. You need to
point the app at the one already in the repo (which has the correct HealthKit
privacy keys that this branch fixes).

1. Click the blue project icon at the top of the file navigator.
2. Select the **OfflineQardioArm** target, then the **Build Settings** tab.
3. In the search box, type `info.plist file`.
4. Double-click **Info.plist File** and set it to
   `OfflineQardioArm/Info.plist`.
5. Still in Build Settings, search for `generate info.plist`. Set
   **Generate Info.plist File** to **No** (so Xcode uses ours).
6. Search for `code signing entitlements` and set it to
   `OfflineQardioArm/OfflineQardioArm.entitlements`.

### Add the HealthKit capability

1. Target → **Signing & Capabilities** tab.
2. Click **+ Capability** (top-left of that pane).
3. Double-click **HealthKit**. A HealthKit section appears in the list.
4. Leave "Clinical Health Records" unchecked — the app doesn't use them.

### Confirm signing

In **Signing & Capabilities**:
- **Automatically manage signing:** checked
- **Team:** your Personal Team
- **Bundle Identifier:** the one you set in step 5

Xcode will provision everything automatically. If you see a red error here, it
usually means the bundle identifier is already taken — change it to something
more unique.

---

## 7. Run on the iPhone

1. At the top of the Xcode window, next to the app name, there's a destination
   picker. Click it and choose **your iPhone** (it should appear by name once
   connected and trusted).
2. Press **⌘R** (or click the ▶ Play button).
3. First build takes a minute. Xcode compiles, signs, copies to the phone, and
   launches.

### First-run error: "Untrusted Developer"

Expected the first time. On the iPhone:

1. **Settings → General → VPN & Device Management**.
2. Under **Developer App**, tap your Apple ID.
3. Tap **Trust "<your Apple ID>"**, then **Trust** again.
4. Back in Xcode, press ▶ again.

> Free Personal Team builds expire after **7 days**. Just re-run from Xcode
> whenever you want to keep using the app.

---

## 8. Test the HealthKit sync (the thing we actually fixed)

### 8a. Grant permission

1. When the app opens, walk through the tutorial until you reach the Apple
   Health screen.
2. Tap **Allow**. iOS shows the system sheet: "OfflineQardioArm" Would Like
   Access to Health Data.
3. Tap **Turn On All**, then **Allow**.
4. Back in the app, you should see **Authenticated** in green.

> **If the Health permission sheet never appears** → the Info.plist fix didn't
> take. Double-check step 6. This is exactly the bug this branch repairs; the
> previous App Store build missed these keys and the sheet silently failed.

### 8b. Take a reading

**With a real QardioArm cuff:**

1. Put 4 fresh AAA batteries in the cuff. Low batteries cause failed reads —
>  the app warns below 25%.
2. In the app, tap **Connect to QardioArm**, then **Get Reading → Single
   Reading**. Put the cuff on; it will pump and read.
3. When the sheet closes, the reading appears in the chart.

**Without a cuff (smoke-test only):** you can exercise the UI paths, but you
can't verify a real save. For HealthKit you need a real reading.

### 8c. Verify the data landed in Apple Health

1. Open the **Health** app on your iPhone.
2. **Browse → Body Measurements → Blood Pressure**. You should see today's
   systolic/diastolic reading with source "OfflineQardioArm".
3. **Browse → Heart → Heart Rate**. Your pulse should be there too.

If both are visible, the fix is working.

---

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Health permission sheet doesn't appear | Info.plist not wired up | Step 6 — make sure `Info.plist File` is set and `Generate Info.plist File` is **No** |
| App crashes when tapping **Allow** on Health | Old code path with `fatalError` | Make sure you're on branch `claude/fix-apple-health-sync-JeAeo` |
| Xcode says "Could not launch" / "developer cannot be trusted" | Profile not trusted | Step 7 — trust the developer under Device Management |
| "HealthKit is not available" at runtime | HealthKit capability missing | Step 6 — add HealthKit capability on the target |
| Bundle ID already in use | Someone else used that ID | Change the Organization Identifier to something more unique |
| Readings don't show in Health app | Toggle off in Settings | In the app: **Settings → Save readings to Apple Health → On** |
| Build expired after 7 days | Personal Team limit | Re-run from Xcode with the phone connected; Xcode re-signs |
| Can't find iPhone in destination picker | Not paired / not unlocked | Unlock phone, tap Trust on the Mac prompt, wait for Xcode to finish "preparing" the device |

---

## 10. Day-to-day workflow once it's set up

- Pull new changes: `git pull` in the cloned repo. Xcode picks them up
  automatically because we added the files by reference (step 5, "Copy items
  if needed: unchecked").
- Press **⌘R** to rebuild and re-deploy.
- To read device logs while the app runs: Xcode → **View → Debug Area → Show
  Debug Area** (⇧⌘Y). The `print(...)` statements in `HealthKitController`
  show up here, which is useful for diagnosing save failures.

---

## 11. What you can't test on the simulator

- HealthKit (always returns "not available")
- CoreBluetooth / the QardioArm cuff
- The real end-to-end sync

The simulator is only useful for UI tweaks. The `OfflineQardioArmApp.swift`
file already swaps in a fake `BluetoothController` under
`#if targetEnvironment(simulator)` so the UI renders without a device, but
nothing actually saves.
