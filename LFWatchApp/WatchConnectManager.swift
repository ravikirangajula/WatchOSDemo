//
//  WatchConnectManager.swift
//  LFWatchApp
//
//  Created by Ravikiran Gajula on 15/2/23.
//

import Foundation
import WatchConnectivity

struct NotificationMessage: Identifiable {
    let id = UUID()
    let text: String
}

final class WatchConnectManager: NSObject {
    static let shared = WatchConnectManager()
    @Published var notificationMessage: NotificationMessage? = nil
    var handler: ((_ messageValue: String) -> Void)?
    var startWorkout: (() -> Void)?

    private let kMessageKey = "message"
    var outPut = ""
    private override init() {
          super.init()
          if WCSession.isSupported() {
              WCSession.default.delegate = self
              WCSession.default.activate()
          }
      }
    
    func send(_ message: String, completion: @escaping(_ outPutString: String?) -> ()) {
         guard WCSession.default.activationState == .activated else {
             print("WCSession: \(WCSession.default.activationState))")
             outPut = "WC \(WCSession.default.activationState)"
             completion("WC \(WCSession.default.activationState)")
           return
         }
         #if os(iOS)
         guard WCSession.default.isWatchAppInstalled else {
             print("IOS App: isWatchAppInstalled: \(WCSession.default.isWatchAppInstalled))")
             outPut = "WAinst: \(WCSession.default.isWatchAppInstalled)"
             completion("WAinst\(WCSession.default.isWatchAppInstalled)")
             return
         }
         #else
         guard WCSession.default.isCompanionAppInstalled else {
             print("WATCH App:  isCompanionAppInstalled: \(WCSession.default.isCompanionAppInstalled))")
             outPut = "WAcompaApp: \(WCSession.default.isCompanionAppInstalled)"
             completion("WAcompaApp\(WCSession.default.isCompanionAppInstalled)")
             return
         }
         #endif
         
         WCSession.default.sendMessage([kMessageKey : message], replyHandler: nil) { error in
             print("Cannot send message: \(String(describing: error))")
             completion("ERR:\(error.localizedDescription)")
         }
     }
}

extension WatchConnectManager: WCSessionDelegate {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let notificationText = message[kMessageKey] as? String {
            DispatchQueue.main.async { [weak self] in
                print("HeartRate: \(message)")
                if notificationText.uppercased() == "START WO".uppercased() {
                    self?.startWorkout?()
                } else {
                    self?.handler?(notificationText)
                }
            }
        }
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
