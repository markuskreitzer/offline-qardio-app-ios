import SwiftUI

struct BloodPressureView : View {
    @ObservedObject var bluetoothController: BluetoothController
    @ObservedObject var healthKitController: HealthKitController
    @ObservedObject var averageBloodPressureCoordinator: AverageBloodPressureCoordinator = AverageBloodPressureCoordinator.shared
    @AppStorage(Settings.saveToHealthKit) var saveToHealthKit: Bool = false
    @AppStorage(Settings.confirmBeforeSave) var confirmBeforeSave: Bool = true
    @State var presentSingleBloodPressureReading = false
    @State var presentAverageBloodPressureReading = false
    @State private var showingReadingOptions = false
    @State private var pendingReading: BloodPressureReading?

    private var reading: BloodPressureReading { bluetoothController.bloodPressureReading }
    private var isConnected: Bool { bluetoothController.isDeviceConnected() }
    private var hasReading: Bool {
        reading.hasReading && (reading.bloodPressureReadingProgress == .completed || reading.bloodPressureReadingProgress == .savedToHealthKit)
    }

    private func handleCompletedReading(_ reading: BloodPressureReading) {
        guard saveToHealthKit,
              reading.bloodPressureReadingProgress == .completed,
              !healthKitController.guestReading else {
            return
        }
        if confirmBeforeSave {
            pendingReading = reading
        } else {
            _ = healthKitController.saveBloodPressureReading(reading: reading)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ConnectionChip(
                    deviceName: bluetoothController.getDeviceName(),
                    isConnected: isConnected,
                    batteryLevel: bluetoothController.batteryLevel
                )
                .padding(.top, 4)

                if hasReading {
                    ScrollView {
                        VStack(spacing: 16) {
                            BloodPressureHeroView(reading: reading)
                            BloodPressureReadingChart(reading: reading)
                                .frame(height: 320)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    BloodPressureEmptyState(isConnected: isConnected, lastReadingDate: nil)
                }

                if isConnected {
                    Toggle(isOn: $healthKitController.guestReading) {
                        Text(healthKitController.guestReading
                             ? "Your next reading won't be saved."
                             : "Guest Mode")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                    if bluetoothController.batteryLevel < 25 {
                        Label("Low battery — reading may fail.", systemImage: "battery.25")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                actionButton
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .navigationTitle("Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                pendingReading.map { "Save \($0.systolic)/\($0.diastolic) mmHg, \($0.pulseRate) bpm to Apple Health?" } ?? "",
                isPresented: Binding(
                    get: { pendingReading != nil },
                    set: { if !$0 { pendingReading = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Save to Health") {
                    if let reading = pendingReading {
                        _ = healthKitController.saveBloodPressureReading(reading: reading)
                    }
                    pendingReading = nil
                }
                Button("Discard", role: .destructive) {
                    pendingReading = nil
                }
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isConnected {
            Button {
                averageBloodPressureCoordinator.reset()
                showingReadingOptions = true
            } label: {
                Label("Get Reading", systemImage: "waveform.path.ecg")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .sheet(isPresented: $presentSingleBloodPressureReading) {
                handleCompletedReading(reading)
            } content: {
                BloodPressureReadingInActionView()
            }
            .sheet(isPresented: $presentAverageBloodPressureReading) {
                if averageBloodPressureCoordinator.hasReadings {
                    handleCompletedReading(reading)
                }
            } content: {
                AverageBloodPressureReadingInActionView()
            }
            .confirmationDialog("Select Reading Type", isPresented: $showingReadingOptions, titleVisibility: .visible) {
                Button("Single Reading") { presentSingleBloodPressureReading = true }
                Button("Average Reading") { presentAverageBloodPressureReading = true }
            }
        } else {
            Button {
                bluetoothController.scanForPeripherals()
            } label: {
                Label("Connect to QardioArm", systemImage: "antenna.radiowaves.left.and.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

#Preview {
    let reading = BloodPressureReading(systolic: 115, diastolic: 60, atrialPressure: 78, pulseRate: 65, bloodPressureReadingProgress: .savedToHealthKit)
    let bt: BluetoothController = BluetoothController.controllerWithSampleData(reading: reading, batteryLevel: 78)
    return BloodPressureView(bluetoothController: bt, healthKitController: HealthKitController())
}
