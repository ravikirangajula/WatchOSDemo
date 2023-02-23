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
    
    @IBAction func tapOnButton(_ sender: Any) {
           sharedObj.openWatchOSApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {[weak self] in
            self?.sharedObj.send("START WO") { [weak self] outPutString in
                DispatchQueue.main.async {
                    self?.titleLabel.text = outPutString
                }
            }
        }
    }

    @IBAction func endWorkout(_ sender: Any) {
        self.sharedObj.send("END WO") { [weak self] outPutString in
            DispatchQueue.main.async {
                self?.titleLabel.text = outPutString
            }
        }

        
    }
}


