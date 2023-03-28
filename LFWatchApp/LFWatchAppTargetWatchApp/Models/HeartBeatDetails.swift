//
//  HeartBeatDeatils.swift
//  LFConnectWatch Watch App
//
//  Created by Ravikiran Gajula on 24/3/23.
//  Copyright © 2023 Life Fitness. All rights reserved.
//

import Foundation

struct HeartBeatDetails: Identifiable {
    let id: ObjectIdentifier
    let heartBeat: HeartBeat
    let count: Int

}
