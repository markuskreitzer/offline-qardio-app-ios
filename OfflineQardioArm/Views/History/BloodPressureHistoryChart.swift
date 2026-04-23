import SwiftUI
import Charts

struct BloodPressureHistoryChart: View {
    let readings: [BloodPressureReading]

    var body: some View {
        Chart {
            ForEach(readings) { reading in
                LineMark(
                    x: .value("Date", reading.date),
                    y: .value("Systolic", reading.systolic),
                    series: .value("Metric", "Systolic")
                )
                .foregroundStyle(.red)
                .symbol(.circle)

                LineMark(
                    x: .value("Date", reading.date),
                    y: .value("Diastolic", reading.diastolic),
                    series: .value("Metric", "Diastolic")
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
            }

            RuleMark(y: .value("Systolic target", 120))
                .foregroundStyle(.red.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            RuleMark(y: .value("Diastolic target", 80))
                .foregroundStyle(.blue.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
        }
        .chartForegroundStyleScale([
            "Systolic": .red,
            "Diastolic": .blue
        ])
        .chartYScale(domain: yDomain)
        .chartLegend(position: .bottom)
    }

    private var yDomain: ClosedRange<Int> {
        guard !readings.isEmpty else { return 40...180 }
        let lo = readings.map { Int($0.diastolic) }.min() ?? 40
        let hi = readings.map { Int($0.systolic) }.max() ?? 180
        return max(30, lo - 10)...min(220, hi + 10)
    }
}

#Preview {
    let now = Date()
    let cal = Calendar.current
    let readings: [BloodPressureReading] = (0..<10).map { i in
        BloodPressureReading(
            systolic: UInt16(115 + (i % 4) * 3),
            diastolic: UInt16(75 + (i % 3) * 2),
            atrialPressure: 0,
            pulseRate: UInt16(65 + i),
            bloodPressureReadingProgress: .savedToHealthKit,
            date: cal.date(byAdding: .day, value: -i * 2, to: now) ?? now
        )
    }.reversed()
    return BloodPressureHistoryChart(readings: readings)
        .frame(height: 300)
        .padding()
}
