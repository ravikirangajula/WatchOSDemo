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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sharedObj.handler = { [weak self] obj in
            self?.titleLabel.text = obj
        }
    }
    
    @IBAction func tapOnButton(_ sender: Any) {
        sharedObj.send("iOS App") { [weak self] outPutString in
            DispatchQueue.main.async {
                self?.titleLabel.text = outPutString
            }
        }
    }
}


