# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

**OfflineQardioArm** — a SwiftUI iOS app that talks to the QardioArm Bluetooth
blood-pressure monitor directly (no vendor cloud), displays readings, and
optionally pushes them to Apple Health.

- Language: Swift / SwiftUI
- Min target: iOS 17+ (uses `HKQuantityType(.bloodPressureSystolic)` typed
  constants and iOS 26 UI tweaks)
- Build system: Xcode (the `project.pbxproj` is intentionally not checked in;
  see commit `586a033 chore: Remove xcodeproject`). To build, open the folder
  in Xcode and regenerate/attach a project, or build from a local Xcode project
  that references the `OfflineQardioArm/` sources.
- License: see `LICENSE.md`. Privacy policy: see `PRIVACY.md`.

## Layout

```
OfflineQardioArm/
├── OfflineQardioArmApp.swift       # @main, wires shared controllers
├── ContentView.swift               # Root: tutorial gate -> BloodPressureView
├── Info.plist                      # Privacy descriptions (HealthKit)
├── OfflineQardioArm.entitlements   # com.apple.developer.healthkit = true
├── Controllers/
│   ├── BluetoothController.swift           # CoreBluetooth, QardioArm GATT
│   ├── HealthKitController.swift           # HealthKit auth + save
│   └── BloodPressureReadingController.swift
├── Models/
│   ├── BloodPressureReading.swift          # struct + progress enum
│   ├── QardioArmBluetoothDevice.swift      # Service/characteristic UUIDs
│   └── Settings.swift                      # @AppStorage keys
└── Views/
    ├── BloodPressureReading/               # Display, chart, row
    ├── BloodPressureReadingInAction/       # Live reading + average-of-N flow
    ├── Introduction/                       # Tutorial + first-run HealthKit setup
    ├── Settings/
    ├── HealthKitStatusView.swift           # Per-reading save button
    └── HealthAppAuthorisationStatusView.swift
```

## Data flow (blood pressure)

1. `BluetoothController.startReading(onSuccessfulReading:)` writes the start
   command to the QardioArm.
2. Notifications land in `peripheral(_:didUpdateValueFor:error:)`. Bytes are
   decoded into a `BloodPressureReading` (flags `20` + systolic ≤ 200 ⇒
   `.completed`).
3. On `.completed`, the controller invokes `onSuccessfulReading` — currently
   called from `BloodPressureReadingInActionView.onAppear`, which dismisses the
   sheet. The parent `BloodPressureView` then, if the user enabled
   `Settings.saveToHealthKit`, calls
   `HealthKitController.saveBloodPressureReading(reading:)`.
4. Average-of-N readings are accumulated in `AverageBloodPressureCoordinator`;
   the final average is what gets saved.

## HealthKit integration — read this before touching it

Two Info.plist keys are **mandatory** and must stay spelled exactly as Apple
expects — no other key name works:

- `NSHealthShareUsageDescription` (read from Health)
- `NSHealthUpdateUsageDescription` (write to Health)

If either is missing or misspelled, `HKHealthStore.requestAuthorization(...)`
throws, the permission dialog never appears, and the app cannot save readings
to Health. (An earlier release shipped with `HKQuantityTypeIdentifier*` strings
here instead — those are NOT valid privacy keys and caused App Store builds to
silently fail to sync. Do not re-introduce that pattern.)

Entitlement: `com.apple.developer.healthkit` in
`OfflineQardioArm.entitlements`. The app also needs the HealthKit capability
enabled in the target's Signing & Capabilities tab in Xcode, and the provisioning
profile must include HealthKit.

`HealthKitController` conventions:

- `saveBloodPressureReading(reading:)` is `async` and returns `Bool`. The
  previous synchronous version was racy — it returned before
  `HKHealthStore.save`'s completion handler ran. Do not re-introduce a
  synchronous variant.
- `requestAuthorization()` is `async throws`. Callers should handle the error
  (e.g. show it), never `fatalError` on failure — that crashes the App Store
  build for any user whose environment triggers an auth error.
- `isAuthorized()` checks write (`.sharingAuthorized`) status. HealthKit
  intentionally hides read authorization state for privacy, so never rely on
  read-auth checks.
- `guestReading` skips saving the next reading (toggle in `BloodPressureView`).
- `lastSaveError: String?` is `@Published`; views should bind to it to surface
  save/auth failures to the user.

## Common tasks

- **Adding a new HealthKit quantity type:** add to `HealthKitController.allTypes`
  AND request it on both `toShare:` and `read:` in `requestAuthorization`.
  Verify `NSHealth*UsageDescription` still cover the new data type.
- **Changing the reading decode:** see `peripheral(_:didUpdateValueFor:error:)`
  in `BluetoothController.swift`. Byte layout is documented inline.
- **Testing on simulator:** `OfflineQardioArmApp.swift` swaps in
  `BluetoothController.controllerWithSampleData` / `...NoSampleData` under
  `#if targetEnvironment(simulator)`. HealthKit is not available on the
  simulator — real-device testing is required for any HealthKit change.

## Conventions

- Controllers are `ObservableObject` singletons exposed via `static let shared`.
- Persistence of simple flags uses `@AppStorage(Settings.<key>)`.
- There is no unit-test target in this repo. Verify changes by building in
  Xcode and running on a device.
- Branches: feature/fix work goes on `claude/<topic>` branches per the task
  brief; do not push directly to `main`.
