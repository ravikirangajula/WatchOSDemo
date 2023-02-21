//
//  ViewController.swift
//  LFWatchApp
//
//  Created by Ravikiran Gajula on 14/2/23.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    let sharedObj = WatchConnectManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    @IBAction func tapOnButton(_ sender: Any) {
        sharedObj.send("from ios") { outPutString in
            print("Message: \(outPutString)")
        }
    }
}

extension ViewController: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")

    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.titleLabel.text = "\(error?.localizedDescription)"
        }
        print("Error == \(error) \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.titleLabel.text = message["message"] as? String ?? "App"
        }
        print("message == \(message)")
    }
}
