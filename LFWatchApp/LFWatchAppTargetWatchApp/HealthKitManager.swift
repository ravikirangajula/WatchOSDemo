//
//  HealthKitManager.swift
//  LFWatchAppTargetWatchApp
//
//  Created by Ravikiran Gajula on 21/2/23.
//

import Foundation
import HealthKit

class HealthKitManager: NSObject {
   
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")

    var heartRateValue = 0
    var getHeartRate: ((_ rateValue: String) -> Void)?
    var getHeartRateQueryObject: ((_ rateValue: HKSample) -> Void)?

    var heartRateQuery:HKSampleQuery?
    
    override init() {
        super.init()
    }

    func start() {
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }
    
    func autorizeHealthKit() {
        
        // Used to define the identifiers that create quantity type objects.
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        // Requests permission to save and read the specified data types.
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        
        // We want data points from our current device
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        // A query that returns changes to the HealthKit store, including a snapshot of new changes and continuous monitoring as a long-running query.
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            // A sample that represents a quantity, including the value and the units.
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
            
        }
        
        // It provides us with both the ability to receive a snapshot of data, and then on subsequent calls, a snapshot of what has changed.
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        // query execution
        
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        // variable initialization
        var lastHeartRate = 0.0
        
        // cycle and value assignment
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
            self.heartRateValue = Int(lastHeartRate)
            getHeartRate?("\(Int(lastHeartRate))")
        }
    }
    
    func getTodaysHeartRates(completion: @escaping(_ heartRate: String) ->()) {
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)
        
        guard let startDate:NSDate = calendar.date(from: components) as NSDate? else { return }
        var dayComponent    = DateComponents()
        dayComponent.day    = 1
        let endDate:NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        
        print("START DATE: \(startDate) End date: \(endDate)")
        
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: nil, options: [])
        let sortDescriptors = [
            NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        ]
        
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        let heartRateType:HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

        heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 4, sortDescriptors: sortDescriptors, resultsHandler: { [weak self] (query, results, error) in
            guard error == nil else {
                print("error")
                return
            }
            completion(self?.getHeartRateValue(result: results?.first) ?? "")
        })
        
        healthStore.execute(heartRateQuery!)
    }
    
    private func getHeartRateValue(result: HKSample?) -> String {
        guard let currData:HKQuantitySample = result as? HKQuantitySample else { return "Nan" }
        return "\(currData.quantity.doubleValue(for: heartRateQuantity))"
    }
}

extension HealthKitManager {
    
    func createHeartRateStreamingQuery() -> HKQuery? {
        
        let earlyDate = Calendar.current.date(
          byAdding: .minute,
          value: -2,
          to: Date())
        print("Start = \(earlyDate)")
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: earlyDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            
            self.updateHeartRate(sampleObjects?.first)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples?.first)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(_ samples: HKSample?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let sample =  heartRateSamples.last else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateQuantity)
            //self.getHeartRate?("\(Int(value))")
            self.getHeartRateQueryObject?(sample)
        }
    }
    

}
