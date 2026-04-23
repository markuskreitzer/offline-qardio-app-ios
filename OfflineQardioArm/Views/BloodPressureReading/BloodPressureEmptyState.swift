import SwiftUI

struct BloodPressureEmptyState: View {
    let isConnected: Bool
    let lastReadingDate: Date?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            Text("No reading yet")
                .font(.title2.weight(.semibold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let lastReadingDate {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Last reading \(lastReadingDate, format: .relative(presentation: .named))")
                        .font(.footnote)
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var subtitle: String {
        isConnected
            ? "Tap Get Reading to start a measurement."
            : "Connect your QardioArm to take a reading."
    }
}

#Preview("Disconnected") {
    BloodPressureEmptyState(isConnected: false, lastReadingDate: nil)
}

#Preview("Connected, with history") {
    BloodPressureEmptyState(
        isConnected: true,
        lastReadingDate: Calendar.current.date(byAdding: .hour, value: -3, to: .now)
    )
}
