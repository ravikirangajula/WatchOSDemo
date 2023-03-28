/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The workout manager that interfaces with HealthKit.
*/

import Foundation
import HealthKit
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject {
    let sharedObj = WatchConnectManager.shared
    private static let seconds: TimeInterval = 60
    private static let minute = seconds * 60
//    private static let minute: TimeInterval = 60
    private static let hour = minute * 60
    private static let day = hour * 24
    private var count = 0
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
        }
    }

    @Published var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }

    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    private let workoutDelayDuration = 0.5
    private let heartRateQuantity = HKUnit(from: "count/min")
    var getHeartRateBPM: ((_ rateValue: Int) -> Void)?
    var updateError: ((_ errorMsg: String?) -> Void)?
    @Published var errorMessage: String?
    @Published var endWorkoutSelected: Bool = false {
        didSet {
            if endWorkoutSelected == true {
                endWorkoutSelected = false
                resetWorkout()
            }
        }
    }
    // Start the workout.
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor

        // Create the session and obtain the workout builder.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            return
        }

        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
        }
        watchConnectionManagerCallBacks()
    }

    // Request authorization to access HealthKit.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.activitySummaryType()
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] (success, error) in
            guard let self = self else { return }
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.workoutDelayDuration) {
                    self.updateAuthorizationStatus()
                    self.sharedObj.send(WCManagerWorkoutControllers.startWorkout.rawValue, completion: { [weak self] outPutString in
                        self?.errorMessage = outPutString
                    })
                }
            }
           completion(success, error)
        }
    }

    // MARK: - Session State Control

    // The app's workout state.
    @Published var running = false

    func togglePause() {
        if running == true {
            self.pause()
        } else {
            resume()
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func endWorkout() {
        session?.end()
       // endWorkoutSelected = true
        resetWorkout()
    }

    // MARK: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    @Published var data: [HeartBeatDetails] = []
    @Published var statusText = ""

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                debugPrint("Heart Rate == \(self.heartRate)")
                debugPrint("averageHeartRate Rate == \(self.averageHeartRate)")
                let value = self.heartRate.formatted(.number.precision(.fractionLength(0)))
                self.sharedObj.send("\(value)") { [weak self] outPutString in
                    debugPrint("Error == \(outPutString)")
                }
                var time = Date.now.addingTimeInterval(Double(self.count))
                self.data.append(.init(
                    id: .init(HeartBeatDetails.self),
                    heartBeat: .init(beat: Int(self.heartRate), time: time), count: self.count)
                )
                self.count = self.count + 1

            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
        }
    }

    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        workout = nil
        session = nil
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
        distance = 0
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async { [weak self] in
            self?.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async { [weak self] in
                        self?.workout = workout
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            let statistics = workoutBuilder.statistics(for: quantityType)
            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}


extension WorkoutManager {
    
    private func watchConnectionManagerCallBacks() {
        sharedObj.endWorkout = { [weak self] in
            self?.endWorkout()
        }
        
        sharedObj.pauseWorkout = { [weak self] in
            self?.pause()
        }
    }
    
    func updateAuthorizationStatus() {
        guard let stepQtyType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let status = self.healthStore.authorizationStatus(for: stepQtyType)
        switch status {
        case .sharingAuthorized:
            self.statusText =  "Start workout on phone to begin tracking."
        default:
            self.statusText =  "Cannot connect, doublecheck permissions in app."
        }
    }
}
