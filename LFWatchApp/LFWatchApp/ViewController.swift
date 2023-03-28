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
    var sharedObj = WatchConnectManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sharedObj = WatchConnectManager.shared
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sharedObj.didReceiveMessageFromWCManager = { [weak self] obj in
            self?.titleLabel.text = "Heart rate: \(obj)"
        }
    }
    
    @IBAction func runTap(_ sender: Any) {
        sharedObj.startWorkoutInAppleWatch(activityType: .run)
    }

    @IBAction func cycleTap(_ sender: Any) {
        sharedObj.startWorkoutInAppleWatch(activityType: .bike)
    }
    
    @IBAction func tapOnButton(_ sender: Any) {
        sharedObj.startWorkoutInAppleWatch(activityType: .walk)
    }

    @IBAction func endWorkout(_ sender: Any) {
        self.sharedObj.endWorkoutInWatchApp()
    }
}


