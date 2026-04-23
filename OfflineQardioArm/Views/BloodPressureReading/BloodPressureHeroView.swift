import SwiftUI

struct BloodPressureHeroView: View {
    let reading: BloodPressureReading
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(reading.systolic)")
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("/")
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("\(reading.diastolic)")
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .contentTransition(.numericText())

            Text("mmHg")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                categoryBadge
                if reading.pulseRate > 0 {
                    pulseChip
                }
            }

            DisclosureGroup(isExpanded: $showDetails) {
                HStack {
                    Text("Mean Arterial Pressure")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(reading.atrialPressure) mmHg")
                        .font(.subheadline.monospacedDigit())
                }
                .padding(.top, 8)
            } label: {
                Text("Details")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background.secondary)
        )
    }

    private var categoryBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(reading.category.color)
                .frame(width: 8, height: 8)
            Text(reading.category.label)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(reading.category.color.opacity(0.15))
        )
    }

    private var pulseChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.caption)
            Text("\(reading.pulseRate) bpm")
                .font(.subheadline.weight(.semibold).monospacedDigit())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.red.opacity(0.12))
        )
    }
}

#Preview("Normal") {
    BloodPressureHeroView(reading: BloodPressureReading(
        systolic: 118, diastolic: 76, atrialPressure: 90, pulseRate: 66,
        bloodPressureReadingProgress: .savedToHealthKit
    ))
    .padding()
}

#Preview("Stage 1") {
    BloodPressureHeroView(reading: BloodPressureReading(
        systolic: 135, diastolic: 85, atrialPressure: 102, pulseRate: 78,
        bloodPressureReadingProgress: .savedToHealthKit
    ))
    .padding()
}
