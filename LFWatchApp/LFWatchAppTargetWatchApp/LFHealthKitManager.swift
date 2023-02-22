//
//  LFHealthKitManager.swift
//  LFWatchAppTargetWatchApp
//
//  Created by Ravikiran Gajula on 21/2/23.
//

import UIKit
import HealthKit
import WatchConnectivity

class LFHealthKitManager: NSObject {
    private var healthStore = HKHealthStore()
    private let heartRateQuantity = HKUnit(from: "count/min")
    private let sharedObj = WatchConnectManager.shared
    var getHeartRateBPM: ((_ rateValue: Int) -> Void)?
    var updateError: ((_ errorMsg: String?) -> Void)?
    var session : HKWorkoutSession?

    override init() {
        super.init()
    }
}

extension LFHealthKitManager {
    
    func startHealthKit() {
        self.autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
        setUpBackgroundDeliveryForDataTypes()
    }
    
    func autorizeHealthKit() {
        let healthKitTypes: Set = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }
    
    private func setUpBackgroundDeliveryForDataTypes() {
    let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { query, completion, erroObhes in
            print("\(query)")
        }
        healthStore.execute(query)
        
        healthStore.enableBackgroundDelivery(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!, frequency: .immediate) { success, error in
            print("\(error)")
        }
    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        
        // 1
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        // 2
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            // 3
        guard let samples = samples as? [HKQuantitySample] else {
            return
        }
            
        self.process(samples, type: quantityTypeIdentifier)

        }
        
        // 4
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        
        // 5
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        var lastHeartRate = 0.0
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
//            sharedObj.send("\(Int(lastHeartRate))") { [weak self] outPutString in
//                self?.updateError?(outPutString)
//            }
            getHeartRateBPM?(Int(lastHeartRate))
        }
    }
}
