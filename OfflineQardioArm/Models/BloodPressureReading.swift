//
//  BloodPressureReading.swift
//  OfflineQardioArm
//
//  Created by Edward Vella on 25/07/2025.
//
import SwiftUI
import Foundation

struct BloodPressureReading : Identifiable, Hashable {
    var id: UUID = UUID()
    var systolic: UInt16
    var diastolic: UInt16
    var atrialPressure: UInt16
    var pulseRate: UInt16
    var bloodPressureReadingProgress: BloodPressureReadingProgress
    var syncedToHealth: Bool = false
    var date: Date = Date()
}

extension BloodPressureReading {
    static var examples: [BloodPressureReading] {
        [
            BloodPressureReading(systolic: 120, diastolic: 80, atrialPressure: 90, pulseRate: 65, bloodPressureReadingProgress: .savedToHealthKit),
            BloodPressureReading(systolic: 130, diastolic: 85, atrialPressure: 95, pulseRate: 70, bloodPressureReadingProgress: .savedToHealthKit),
            BloodPressureReading(systolic: 110, diastolic: 75, atrialPressure: 85, pulseRate: 60, bloodPressureReadingProgress: .savedToHealthKit),
            BloodPressureReading(systolic: 140, diastolic: 90, atrialPressure: 100, pulseRate: 75, bloodPressureReadingProgress: .savedToHealthKit),
            BloodPressureReading(systolic: 125, diastolic: 82, atrialPressure: 92, pulseRate: 68, bloodPressureReadingProgress: .savedToHealthKit)
        ]
    }
}

enum BloodPressureCategory {
    case none
    case low
    case normal
    case elevated
    case stage1
    case stage2
    case crisis

    var label: String {
        switch self {
        case .none: return "—"
        case .low: return "Low"
        case .normal: return "Normal"
        case .elevated: return "Elevated"
        case .stage1: return "Stage 1"
        case .stage2: return "Stage 2"
        case .crisis: return "Crisis"
        }
    }

    var color: Color {
        switch self {
        case .none: return .secondary
        case .low: return .blue
        case .normal: return .green
        case .elevated: return .yellow
        case .stage1: return .orange
        case .stage2: return .red
        case .crisis: return .pink
        }
    }
}

extension BloodPressureReading {
    var category: BloodPressureCategory {
        let s = Int(systolic), d = Int(diastolic)
        if s == 0 || d == 0 { return .none }
        if s >= 180 || d >= 120 { return .crisis }
        if s >= 140 || d >= 90 { return .stage2 }
        if s >= 130 || d >= 80 { return .stage1 }
        if s >= 120 { return .elevated }
        if s < 90 || d < 60 { return .low }
        return .normal
    }

    var hasReading: Bool { systolic > 0 && diastolic > 0 }
}

enum BloodPressureReadingProgress {
    case started
    case cancelled
    case completed
    case notStarted
    case failed
    case savedToHealthKit
}
