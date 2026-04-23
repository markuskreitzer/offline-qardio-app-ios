import Foundation

enum HistoryRange: String, CaseIterable, Identifiable {
    case week, month, year, all

    var id: Self { self }

    var label: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .all: return "All"
        }
    }

    func startDate(from now: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .week: return cal.date(byAdding: .day, value: -7, to: now)
        case .month: return cal.date(byAdding: .month, value: -1, to: now)
        case .year: return cal.date(byAdding: .year, value: -1, to: now)
        case .all: return nil
        }
    }
}
