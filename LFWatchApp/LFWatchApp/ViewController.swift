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
        sharedObj.handler = { [weak self] obj in
            self?.titleLabel.text = obj
        }
    }
    
    @IBAction func tapOnButton(_ sender: Any) {
        sharedObj.send("from ios App") { [weak self] outPutString in
            DispatchQueue.main.async {
                self?.titleLabel.text = outPutString
            }
        }
    }
}


