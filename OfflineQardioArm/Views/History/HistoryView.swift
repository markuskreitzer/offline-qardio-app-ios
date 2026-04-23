import SwiftUI

struct HistoryView: View {
    @ObservedObject var healthKitController: HealthKitController = HealthKitController.shared
    @State private var range: HistoryRange = .month
    @State private var readings: [BloodPressureReading] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Range", selection: $range) {
                    ForEach(HistoryRange.allCases) { r in
                        Text(r.label).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let errorMessage {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await load() } }
                    }
                    .padding()
                    Spacer()
                } else if readings.isEmpty {
                    Spacer()
                    Text("No readings in this range.")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    BloodPressureHistoryChart(readings: readings)
                        .frame(height: 320)
                        .padding(.horizontal)

                    List(readings.reversed()) { reading in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(reading.systolic)/\(reading.diastolic) mmHg")
                                    .font(.headline)
                                Text(reading.date, format: .dateTime.month().day().year().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if reading.pulseRate > 0 {
                                Text("\(reading.pulseRate) bpm")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .task(id: range) { await load() }
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let start = range.startDate(from: Date())
            readings = try await healthKitController.fetchBloodPressureHistory(start: start)
        } catch {
            errorMessage = error.localizedDescription
            readings = []
        }
        isLoading = false
    }
}

#Preview {
    HistoryView()
}
