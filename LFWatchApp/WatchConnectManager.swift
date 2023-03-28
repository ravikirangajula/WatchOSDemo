//
//  WatchConnectManager.swift
//  LFWatchApp
//
//  Created by Ravikiran Gajula on 15/2/23.
//

import Foundation
import WatchConnectivity
import HealthKit

enum WCManagerWorkoutType: String {
    case walk
    case run
    case bike
    case eliptical
    case arcTraining
    case climb
    case rower
    case LFFlexibility
    case hit
    case strength
    case LFCrossTraining
}

enum WCManagerWorkoutControllers: String {
    case startWorkout
    case endWorkout
    case pauseWorkout
}

struct NotificationMessage: Identifiable {
    let id = UUID()
    let text: String
}

final class WatchConnectManager: NSObject {
    static let shared = WatchConnectManager()
    @Published var notificationMessage: NotificationMessage? = nil
    var didReceiveMessageFromWCManager: ((_ messageValue: String) -> Void)?
    var startWorkoutWithSelectedActivity: ((_ workoutType: HKWorkoutActivityType) -> Void)?

    var startWorkout: (() -> Void)?
    var endWorkout: (() -> Void)?
    var pauseWorkout: (() -> Void)?

    private let kMessageKey = "message"
    var outPut = ""
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
#if os(iOS)
    func isWatchAppAvailable() -> Bool {
        return WCSession.isSupported() && WCSession.default.isWatchAppInstalled
    }
    
    func launchWatchApp(activityType: HKWorkoutActivityType, completion: @escaping (Bool, Error?) -> Void) {
        openWatchOSApp(activityType: activityType) { [weak self] sucess, error in
            guard let _ = self else { return }
            debugPrint("Open WatchApp == \(sucess) Error == \(error)")
            completion(sucess, error)
        }
    }
    
    func pauseWorkoutInWatchApp() {
        send(WCManagerWorkoutControllers.pauseWorkout.rawValue) { [weak self] outPutString in
            guard let _ = self else { return }
            debugPrint("Pause Workout response == \(outPutString ?? "NA")")
        }
    }
    
    func endWorkoutInWatchApp() {
        send(WCManagerWorkoutControllers.endWorkout.rawValue) { [weak self] outPutString in
            guard let _ = self else { return }
            debugPrint("End Workout response == \(outPutString ?? "NA")")
        }
    }
    
    func startWorkoutInAppleWatch(activityType: WCManagerWorkoutType) {
        var message: WCManagerWorkoutType = .walk
        switch activityType {
        case .walk:
            message = .walk
        case .run:
            message = .run
        case .bike:
            message = .bike
        case .eliptical:
            message = .eliptical
        case .climb:
            message = .climb
        case .rower:
            message = .rower
        case .strength:
            message = .strength
        case .arcTraining:
            message = .arcTraining
        case .LFFlexibility:
            message = .LFFlexibility
        case .hit:
            message = .hit
        case .LFCrossTraining:
            message = .LFCrossTraining
        }
        send(message.rawValue) { [weak self] outPutString in
            guard let _ = self else { return }
            debugPrint("send message response == \(outPutString ?? "NA")")
        }
    }

    func openWatchOSApp(activityType: HKWorkoutActivityType, completion: @escaping (Bool, Error?) -> Void) {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = activityType
        workoutConfiguration.locationType = .indoor
        if WCSession.isSupported(), WCSession.default.activationState == .activated , WCSession.default.isWatchAppInstalled {
            HKHealthStore().startWatchApp(with: workoutConfiguration, completion: { (success, error) in
                debugPrint("Open WatchApp Error ==> \(error.debugDescription)")
               completion(success, error)
            })
        }
    }
#endif
    
    func send(_ message: String, completion: @escaping(_ outPutString: String?) -> ()) {
        debugPrint("Send message =====> \(message)")
        guard WCSession.default.activationState == .activated else {
            debugPrint("WCSession: \(WCSession.default.activationState))")
            outPut = "WC \(WCSession.default.activationState)"
            completion("WC \(WCSession.default.activationState)")
            return
        }
#if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            debugPrint("IOS App: isWatchAppInstalled: \(WCSession.default.isWatchAppInstalled))")
            outPut = "WAinst: \(WCSession.default.isWatchAppInstalled)"
            completion("WAinst\(WCSession.default.isWatchAppInstalled)")
            return
        }
#else
        guard WCSession.default.isCompanionAppInstalled else {
            debugPrint("WATCH App:  isCompanionAppInstalled: \(WCSession.default.isCompanionAppInstalled))")
            outPut = "WAcompaApp: \(WCSession.default.isCompanionAppInstalled)"
            completion("WAcompaApp\(WCSession.default.isCompanionAppInstalled)")
            return
        }
#endif
        
        WCSession.default.sendMessage([kMessageKey : message], replyHandler: nil) { error in
            debugPrint("Cannot send message: \(String(describing: error))")
            completion("ERR:\(error.localizedDescription)")
        }
    }
}

extension WatchConnectManager: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        debugPrint("WatchConnectManager Session ======>>: \(message)")
        if let notificationText = message[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                print("HeartRate: \(message)")
                if notificationText == WCManagerWorkoutType.run.rawValue  {
                    self?.startSelectedWorkout(selectedWorkoutType: .run)
                } else if notificationText == WCManagerWorkoutType.walk.rawValue  {
                    self?.startSelectedWorkout(selectedWorkoutType: .walk)
                } else if notificationText == WCManagerWorkoutType.bike.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .bike)
                } else if notificationText == WCManagerWorkoutType.rower.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .rower)
                } else if notificationText == WCManagerWorkoutType.climb.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .climb)
                } else if notificationText == WCManagerWorkoutType.eliptical.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .eliptical)
                } else if notificationText == WCManagerWorkoutType.strength.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .strength)
                } else if notificationText == WCManagerWorkoutType.arcTraining.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .arcTraining)
                } else if notificationText == WCManagerWorkoutType.LFFlexibility.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .LFFlexibility)
                }  else if notificationText == WCManagerWorkoutType.hit.rawValue {
                    self?.startSelectedWorkout(selectedWorkoutType: .hit)
                } else if notificationText.uppercased() == WCManagerWorkoutControllers.endWorkout.rawValue.uppercased() {
                    self?.endWorkout?()
                } else if notificationText.uppercased() == WCManagerWorkoutControllers.pauseWorkout.rawValue.uppercased() {
                    debugPrint("PAUSE MESSAGE: \(message)")
                    self?.pauseWorkout?()
                } else {
                    self?.didReceiveMessageFromWCManager?(notificationText)
                }
            }
        }
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif
}

extension WatchConnectManager {
    
     func startSelectedWorkout(selectedWorkoutType: WCManagerWorkoutType) {
        switch selectedWorkoutType {
        case .walk:
            self.startWorkoutWithSelectedActivity?(.walking)
        case .run:
            self.startWorkoutWithSelectedActivity?(.running)
        case .bike:
            self.startWorkoutWithSelectedActivity?(.cycling)
        case .eliptical, .arcTraining:
            self.startWorkoutWithSelectedActivity?(.elliptical)
        case .rower:
            self.startWorkoutWithSelectedActivity?(.rowing)
        case .climb:
            self.startWorkoutWithSelectedActivity?(.climbing)
        case .strength:
            self.startWorkoutWithSelectedActivity?(.mixedCardio)
        case .LFFlexibility:
            self.startWorkoutWithSelectedActivity?(.flexibility)
        case .hit:
            self.startWorkoutWithSelectedActivity?(.highIntensityIntervalTraining)
        case .LFCrossTraining:
            self.startWorkoutWithSelectedActivity?(.crossTraining)

        }
    }
}
