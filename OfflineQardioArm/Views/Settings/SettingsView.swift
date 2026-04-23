import SwiftUI


struct SettingsView : View {
    @AppStorage(Settings.saveToHealthKit) var saveToHealthKit: Bool = false
    @AppStorage(Settings.confirmBeforeSave) var confirmBeforeSave: Bool = true
    @AppStorage("tutorialCompleted") var tutorialCompleted = false
    @ObservedObject var healthKitController: HealthKitController = HealthKitController.shared
    var bluetoothController: BluetoothController = BluetoothController.shared

    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var isExporting = false

    var body : some View {
        Text("Settings")
            .font(.title2)
        VStack {
            List {
                Section(header: Text("Device")) {
                    DeviceConnectionStatusView(
                        deviceName: bluetoothController.getDeviceName(),
                        isConnected: bluetoothController.isDeviceConnected(),
                        batteryLevel: bluetoothController.batteryLevel
                    )
                }
                Section(header: Text("Health App")) {
                    HealthAppAuthorisationStatusView()
                    Toggle(isOn: $saveToHealthKit) {
                        Text("Save readings to Apple Health")
                    }
                    Toggle(isOn: $confirmBeforeSave) {
                        Text("Confirm before saving")
                    }
                    .disabled(!saveToHealthKit)
                    Button("Re-request Health Permission") {
                        Task {
                            try? await healthKitController.requestAuthorization()
                        }
                    }
                }
                .headerProminence(.increased)
                Section(header: Text("Export")) {
                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Text("Export Readings as CSV")
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .disabled(isExporting)
                }
                Section(header: Text("Tutorial")) {
                    Button("Restart Tutorial") {
                        tutorialCompleted.toggle()
                    }
                }
            }
        }
        CopyrightView()
            .sheet(item: Binding(
                get: { exportURL.map { ExportFile(url: $0) } },
                set: { if $0 == nil { exportURL = nil } }
            )) { file in
                ShareLink(item: file.url) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                }
                .padding()
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
    }

    private func exportCSV() {
        isExporting = true
        Task {
            do {
                let readings = try await healthKitController.fetchBloodPressureHistory()
                guard !readings.isEmpty else {
                    await MainActor.run {
                        isExporting = false
                        exportError = "No readings found in Apple Health."
                    }
                    return
                }
                let url = try CSVExporter.writeTemporaryFile(readings)
                await MainActor.run {
                    isExporting = false
                    exportURL = url
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
}

private struct ExportFile: Identifiable {
    var id: URL { url }
    let url: URL
}


#Preview {
    SettingsView()
}
