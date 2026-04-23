# QardioArm BP

An iOS app for the Qardio QardioArm Bluetooth blood pressure monitor. Records readings directly from the device, optionally saves them to Apple Health, and lets you review your history offline — built for people whose QardioArm has outlived the original vendor's app and cloud service.

## Features

- **Direct Bluetooth** pairing and readings with the QardioArm monitor — no account, no cloud.
- **Single or averaged** readings (3-measurement average following AHA methodology).
- **Apple Health integration** — optional, with a **confirm-before-save** dialog so nothing is written without your consent. A Guest Mode toggle lets you take a throwaway reading.
- **History tab** — time-series chart (systolic + diastolic) plus a sortable list, with range filters for Week / Month / Year / All. Data is read directly from Apple Health.
- **CSV export** — share your complete history from Settings via the iOS share sheet (AirDrop, Files, email…).
- **BP category badges** — Normal / Elevated / Stage 1 / Stage 2 / Crisis / Low, colour-coded per AHA guidelines.
- **Offline-first** — no telemetry, no accounts, no network calls.

## Requirements

- iPhone running iOS 18 or later.
- A Qardio QardioArm (any BLE-capable model).
- Xcode 16+ to build from source.

## Building

The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen), because `.xcodeproj` is intentionally gitignored to avoid merge churn.

```bash
brew install xcodegen
xcodegen generate
open OfflineQardioArm.xcodeproj
```

Then in Xcode: select your development team under *Signing & Capabilities*, pick your device, and Run. For free personal teams, the build will need to be re-deployed every 7 days.

## Credits and attribution

This app is a personal fork of the excellent open-source project by **Edward Vella** / [Dwardu Ltd](https://dwardu.com):

- **Upstream**: [dwardu-ltd/offline-qardio-app-ios](https://github.com/dwardu-ltd/offline-qardio-app-ios)
- **Original author**: Edward Vella (`hello@dwardu.com`)
- **Original app**: available on the App Store as "Offline QardioArm"

All the hard parts — reverse-engineering the QardioArm BLE protocol, the reading state machine, the single-reading zone chart, the tutorial flow — are Edward's work. This fork adds a redesigned reading UI, a history tab, CSV export, a HealthKit save-confirmation dialog, and iOS 26 polish.

Please consider supporting the upstream project if you find this useful. If you want the app from an official source, install the upstream version from the App Store.

## License

[GNU AGPL-3.0](LICENSE.md) — inherited from upstream. You are free to use, modify, and redistribute this source under the same terms. If you run a modified version as a network service, you must make your source available to users. See `LICENSE.md` for the full text.

## Privacy

See [PRIVACY.md](PRIVACY.md). Short version: the app talks only to your QardioArm over Bluetooth and, if you allow it, Apple Health. There is no server, no account, no analytics.
