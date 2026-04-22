//
//  HealthKitController.swift
//  OfflineQardioArm
//
//  Created by Edward Vella on 26/07/2025.
//

import HealthKit
import Foundation

class HealthKitController : ObservableObject {
    static let shared: HealthKitController = HealthKitController()

    static let healthStore = HKHealthStore()
    // Define the types of data you want to read or write.

    @Published var healthDataAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published var healthDataAuthorized: Bool = false
    @Published var guestReading: Bool = false
    @Published var lastSaveError: String?
    static let allTypes: Set = [
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic),
        HKQuantityType(.heartRate)
    ]

    init() {
        self.healthDataAuthorized = self.isAuthorized()
    }

    @discardableResult
    func saveBloodPressureReading(reading: BloodPressureReading) async -> Bool {
        if (self.guestReading) {
            print("Guest Reading, Ignoring...")
            await MainActor.run { self.guestReading = false }
            return true
        }
        if (reading.bloodPressureReadingProgress != .completed) {
            print("Reading Incomplete")
            print("Reading Progress: \(reading.bloodPressureReadingProgress)")
            return false
        }
        // Save the blood pressure reading to HealthKit.
        guard healthDataAuthorized else {
            print("Health data not authorized")
            await MainActor.run { self.lastSaveError = "Not authorized to write to Apple Health" }
            return false
        }
        let date = Date()
        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(reading.systolic))
        let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: Double(reading.diastolic))
        let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: Double(reading.pulseRate))
        let systolicSample = HKQuantitySample(type: systolicType, quantity: systolicQuantity, start: date, end: date)
        let diastolicSample = HKQuantitySample(type: diastolicType, quantity: diastolicQuantity, start: date, end: date)
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: date, end: date)

        guard let bloodPressureType = HKObjectType.correlationType(forIdentifier: .bloodPressure) else {
            print("Unable to create the blood pressure correlation type")
            return false
        }

        let objects: Set = [systolicSample, diastolicSample]
        let bloodpressure = HKCorrelation(type: bloodPressureType,
                                          start: date, end: date, objects: objects)

        do {
            try await HealthKitController.healthStore.save([bloodpressure, heartRateSample])
            print("Blood pressure reading saved successfully")
            await MainActor.run { self.lastSaveError = nil }
            return true
        } catch {
            print("Error saving blood pressure reading: \(error.localizedDescription)")
            await MainActor.run { self.lastSaveError = error.localizedDescription }
            return false
        }
    }

    func isAuthorized() -> Bool {
        // `authorizationStatus(for:)` returns the user's share (write) decision
        // for write-enabled types: `.sharingAuthorized` when granted.
        let authorized =
            HealthKitController.healthStore.authorizationStatus(for: HKQuantityType(.bloodPressureDiastolic)) == .sharingAuthorized &&
            HealthKitController.healthStore.authorizationStatus(for: HKQuantityType(.bloodPressureSystolic)) == .sharingAuthorized &&
            HealthKitController.healthStore.authorizationStatus(for: HKQuantityType(.heartRate)) == .sharingAuthorized
        self.healthDataAuthorized = authorized
        return authorized
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        // Request both share (write) and read permissions. Both require the
        // corresponding NSHealth*UsageDescription keys in Info.plist. If either
        // is missing, iOS throws — we surface the error instead of crashing.
        do {
            try await HealthKitController.healthStore.requestAuthorization(
                toShare: HealthKitController.allTypes,
                read: HealthKitController.allTypes
            )
            await MainActor.run { _ = self.isAuthorized() }
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            await MainActor.run { self.lastSaveError = error.localizedDescription }
            throw error
        }
    }
}
