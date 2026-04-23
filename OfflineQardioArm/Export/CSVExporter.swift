import Foundation

enum CSVExporter {
    static func csv(from readings: [BloodPressureReading]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        var lines = ["date,systolic_mmHg,diastolic_mmHg,pulse_bpm"]
        for reading in readings {
            let pulse = reading.pulseRate == 0 ? "" : String(reading.pulseRate)
            lines.append("\(formatter.string(from: reading.date)),\(reading.systolic),\(reading.diastolic),\(pulse)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func writeTemporaryFile(_ readings: [BloodPressureReading]) throws -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let filename = "qardio-readings-\(df.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv(from: readings).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
