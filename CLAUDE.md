# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build system

The Xcode project is generated from `project.yml` via XcodeGen. The `.xcodeproj` is gitignored. The `project.yml` itself **is** tracked and should be kept in sync with source changes (e.g. new folders, renamed targets, bundle ID, deployment target).

```bash
brew install xcodegen        # one-time
xcodegen generate            # regenerate OfflineQardioArm.xcodeproj
```

Build via CLI (preferred over Xcode GUI for speed):

```bash
xcodebuild -project OfflineQardioArm.xcodeproj -scheme OfflineQardioArm -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

The machine's `xcode-select` points to Command Line Tools, not Xcode.app, so **always prefix with `DEVELOPER_DIR`** when calling `xcodebuild`, `xcrun`, or `devicectl`:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild ...
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl device install app --device <id> <app>
```

## Deploying to a physical iPhone (step-by-step)

This repo does **not** include the `.xcodeproj`, so the project must be regenerated before building.

### 1. Prerequisites (one-time per machine)

- Install **Xcode** from the Mac App Store (not just Command Line Tools). The `xcodebuild` and `devicectl` tools are inside the Xcode.app bundle.
- Install XcodeGen: `brew install xcodegen`
- Generate the project: `xcodegen generate`
- Xcode.app must be the active developer directory. If `xcode-select -p` prints `/Library/Developer/CommandLineTools`, run:
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```
  (You will need to enter your Mac password.)

### 2. Apple Developer signing (one-time per Apple ID)

- Open Xcode → **Settings → Accounts → +** → sign in with your Apple ID.
- A **Personal Team** will appear automatically (free). This lets you sign builds for your own devices.
- Open `OfflineQardioArm.xcodeproj` in Xcode, select the **OfflineQardioArm** target → **Signing & Capabilities** → check "Automatically manage signing" and pick your Personal Team.
- Xcode will create a provisioning profile for `com.nostoslabs.OfflineQardioArm`.
- **Note**: free personal-team builds expire in **7 days**. After that the app will refuse to launch until re-deployed.

### 3. iPhone setup (one-time per device)

- **Settings → Privacy & Security → Developer Mode** → toggle **On** → restart iPhone when prompted → after reboot, tap **Turn On** and enter passcode.
- Plug iPhone into Mac via USB (or pair wirelessly in Xcode → Window → Devices and Simulators).

### 4. Build, install, and launch (repeat as needed)

Find your device ID:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl list devices
```

Build (signed for device):
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project OfflineQardioArm.xcodeproj -scheme OfflineQardioArm \
  -destination 'id=YOUR_DEVICE_ID' -configuration Debug \
  -derivedDataPath /tmp/qardio-build -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=${QARDIO_TEAM_ID:-$(security find-identity -v -p codesigning 2>/dev/null | grep -o 'OU=[A-Z0-9]*' | head -1 | cut -d= -f2)} build
```

**How this works:** The command tries the environment variable `QARDIO_TEAM_ID` first (set in `.claude/settings.json`), then falls back to auto-discovering it from your keychain. If both fail, you can find it manually: Xcode → Settings → Accounts → tap your team → read the `Team ID` field, or run `security find-identity -v -p codesigning` and look for the `OU=` value.

Install:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl device install app \
  --device YOUR_DEVICE_ID \
  /tmp/qardio-build/Build/Products/Debug-iphoneos/OfflineQardioArm.app
```

Launch:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun devicectl device process launch \
  --device YOUR_DEVICE_ID com.nostoslabs.OfflineQardioArm
```

**If launch fails with "Locked"**, unlock the iPhone and tap the app icon manually.

### 5. Trust the developer certificate (first install only)

After the first install, iOS blocks the app until you trust the certificate:

- **Settings → General → VPN & Device Management**
- Tap your Apple ID under **Developer App**
- Tap **Trust** → confirm

You must do this once per device. After trusting, the app launches normally until the 7-day expiry.

### 6. Re-deploy after 7 days

Free personal-team signatures expire weekly. When the app stops launching:

1. Re-run the **Build** + **Install** steps above (no need to re-trust the certificate).
2. Launch the app.

If you have a paid Apple Developer account ($99/yr), builds last a full year.

---

There are no automated tests. Manual testing is done on a physical iPhone with a QardioArm device, since CoreBluetooth requires real hardware.

### Lessons learned

- SourceKit/LSP diagnostics are frequently false positives in XcodeGen-generated projects ("Cannot find type in scope" for module-local types). Trust `xcodebuild` over the IDE diagnostics.
- After editing `project.yml` (bundle ID, display name, deployment target, new source paths), run `xcodegen generate` before building.
- iOS deployment target is **18.0** (bumped from 17 because `.labelStyle(.toolbar)` and other APIs require iOS 18).
- Free personal-team signing expires in **7 days** — the app will refuse to launch after that until re-deployed.
- On first install after a build, the user must trust the developer certificate: **Settings → General → VPN & Device Management → Trust**.
- Developer Mode must be enabled on the iPhone (**Privacy & Security → Developer Mode**) for `devicectl` installs.

## App identity

- **Display name**: `QardioArm BP`
- **Bundle ID**: `com.nostoslabs.OfflineQardioArm`
- **Team**: `YOUR_TEAM_ID` — auto-discovered from keychain, or set via `QARDIO_TEAM_ID` in `.claude/settings.json` (local-only, gitignored)
- Upstream: [dwardu-ltd/offline-qardio-app-ios](https://github.com/dwardu-ltd/offline-qardio-app-ios) by Edward Vella / Dwardu Ltd
- License: AGPL-3.0 (inherited from upstream — cannot be changed)

## Architecture

**iOS 18+ SwiftUI app** with three tabs: **Reading**, **History**, **Settings**. No third-party dependencies — purely Apple frameworks (SwiftUI, CoreBluetooth, HealthKit, SwiftData, Charts).

### Controllers (singletons, `@ObservedObject`)

- **`BluetoothController`** (`Controllers/BluetoothController.swift`) — `CBCentralManagerDelegate` + `CBPeripheralDelegate`. Scans for QardioArm peripherals by BLE service UUIDs (`0x1810` for BP, `0x180F` for battery), auto-connects to the first match. Publishes `bloodPressureReading`, `batteryLevel`, connection state. The `startReading()` method writes to a custom characteristic (`583CB5B3-...`) to trigger the cuff, then listens for results on the standard BP measurement characteristic (`0x2A35`). BLE constants live in `Models/QardioArmBluetoothDevice.swift`.

- **`HealthKitController`** (`Controllers/HealthKitController.swift`) — wraps `HKHealthStore`.
  - **Save**: writes BP correlations (systolic + diastolic) plus heart rate samples via `saveBloodPressureReading(reading:)`. Returns `Bool` (fire-and-forget because `HKHealthStore.save` is async but the caller ignores the completion handler).
  - **Query**: `fetchBloodPressureHistory(start:end:)` queries `HKCorrelationType` for `.bloodPressure`, joins heart rate by nearest start-date (within 60s), and returns `[BloodPressureReading]` sorted oldest-first. Used by the History tab and CSV export.
  - **Auth**: requests **both write and read** permissions for `.bloodPressureSystolic`, `.bloodPressureDiastolic`, `.heartRate`. Read permission was added in v2.0; users who previously granted write-only must tap **Re-request Health Permission** in Settings.
  - **Read authorization is intentionally opaque** per Apple's privacy design (`authorizationStatus(for:)` returns `.notDetermined` for read types). Don't gate UI on `isAuthorized()` for reads — attempt the query and surface errors in the view.

- **`AverageBloodPressureCoordinator`** (`Views/BloodPressureReadingInAction/AverageBloodPressureCoordinator.swift`) — state machine for 3-reading averaged measurement (AHA methodology). Accumulates readings until count hits `maximumReadings` (3), then computes simple averages.

### Key data model

`BloodPressureReading` (`Models/BloodPressureReading.swift`) — the central value type: `systolic`, `diastolic`, `atrialPressure`, `pulseRate` (all `UInt16`), plus:
- `bloodPressureReadingProgress` enum (`started → completed → savedToHealthKit`)
- `date: Date = Date()` — set from the HKSample start date when fetched from HealthKit; defaults to `Date()` for live readings
- `category` computed property classifies readings per AHA guidelines (Low / Normal / Elevated / Stage 1 / Stage 2 / Crisis)
- `hasReading: Bool` — `systolic > 0 && diastolic > 0`

`HistoryRange` (`Models/HistoryRange.swift`) — `week/month/year/all` with `startDate(from:)` helper returning a `Date?` (nil for `.all`).

### Data flow

1. **Reading**: User taps "Get Reading" → sheet opens `BloodPressureReadingInActionView` → `BluetoothController.startReading()` writes to BLE characteristic → device returns measurement on `0x2A35` → `BluetoothController.bloodPressureReading` updates → UI reacts via `@ObservedObject`.
2. **Saving**: On `.completed`, if `saveToHealthKit` is enabled and not guest mode:
   - If `confirmBeforeSave` is **on** → confirmation dialog fires (Save / Discard)
   - If **off** → `HealthKitController.saveBloodPressureReading()` writes immediately
3. **History**: `HistoryView` calls `HealthKitController.fetchBloodPressureHistory(start:)` with a date range (week/month/year/all). Data comes from HealthKit, not local storage.
4. **CSV Export**: `CSVExporter` (`Export/CSVExporter.swift`) writes a temp `.csv` file, shared via `ShareLink` from Settings.

### View structure

- `ContentView` — gate on `tutorialCompleted` (persisted in `@AppStorage`), then presents a `TabView` with three tabs. Manages BLE lifecycle: scans on appear/foreground, disconnects on disappear/background.
- `BloodPressureView` — main reading tab. Shows `ConnectionChip` at top, then either `BloodPressureHeroView` + zone chart when a reading exists, or `BloodPressureEmptyState` otherwise. Prominent action button at bottom ("Get Reading" or "Connect to QardioArm"). Guest Mode toggle and low-battery warning inline.
- `HistoryView` — segmented picker for range, `BloodPressureHistoryChart` + sorted list below. Re-fetches when range changes.
- `SettingsView` — device status, HealthKit toggles (`saveToHealthKit`, `confirmBeforeSave`), re-request auth button, CSV export, tutorial restart. `CopyrightView` attributes upstream author and license.
- `TutorialView` — multi-page onboarding flow.

### Settings model

No SwiftData settings store — `Settings.swift` is a struct of `AppStorage` key strings:
- `saveToHealthKit`
- `confirmBeforeSave` (default **true**)

Toggles are bound directly in views with `@AppStorage(Settings.key)`.
