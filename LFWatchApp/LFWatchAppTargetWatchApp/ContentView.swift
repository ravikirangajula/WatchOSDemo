//
//  ContentView.swift
//  LFWatchAppTarget Watch App
//
//  Created by Ravikiran Gajula on 14/2/23.
//
/*import SwiftUI
import HealthKit
import WatchConnectivity

struct ContentView: View {
    let sharedObj = WatchConnectManager.shared
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    
    @State private var value = 0
    
    var body: some View {
        VStack{
            HStack{
                Button("❤️") {
                    sharedObj.send("\(Int(value))") { outPutString in
                        print("\(outPutString)")
                    }
                }.font(.system(size: 50))
                Spacer()
            }
            
            HStack{
                Text("\(value)")
                    .fontWeight(.regular)
                    .font(.system(size: 70))
                Text("BPM")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.red)
                    .padding(.bottom, 28.0)
                
                Spacer()
                
            }

        }
        .padding()
        .onAppear(perform: start)
    }

    
    func start() {
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }
    
    func autorizeHealthKit() {
        let healthKitTypes: Set = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
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
            self.value = Int(lastHeartRate)
            sharedObj.send("\(Int(lastHeartRate))") { outPutString in
                print("\(outPutString) \(outPutString)")
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthKitObject = LFHealthKitManager()
    let sharedObj = WatchConnectManager.shared

    @State private var value = 0 {
        didSet {
            sharedObj.send("\(Int(value))") { outPutString in
                if let error = outPutString, error.contains("ERR:") {
                    errorStatus = error
                } else {
                    errorStatus = "connection err: \(outPutString ?? "CE")"
                }
            }
        }
    }
    @State private var errorStatus = ""
    @State private var iosString = ""

    var body: some View {
        VStack{
            HStack{
                Text("\(iosString)")
                Text(healthKitObject.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                Button("❤️") {
                    sharedObj.send("\(Int(value))") { outPutString in
                        if let error = outPutString, error.contains("ERR:") {
                            errorStatus = error
                        } else {
                            errorStatus = "connection err: \(outPutString ?? "CE")"
                        }
                    }
                }.font(.system(size: 50))
                Spacer()
            }
            
            HStack{
                Text("\(value)")
                    .fontWeight(.regular)
                    .font(.system(size: 70))
                
                Text("LFBPM")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.red)
                    .padding(.bottom, 28.0)
                Spacer()
                
            }
            Text("\(errorStatus)")
                .fontWeight(.regular)
                .font(.system(size: 8))

        }
        .padding()
        .onAppear {
            start()
        }
    }

    
    func start() {
        healthKitObject.startHealthKit()
        callBacks()
        //testingMethod()
    }

    func callBacks() {
        healthKitObject.getHeartRateBPM = { bpmValue in
            DispatchQueue.main.async {
                print("vale == \(bpmValue)")
                value = bpmValue
                errorStatus = ""
                sharedObj.send("\(Int(value))") { outPutString in
                    if let error = outPutString, error.contains("ERR:") {
                        errorStatus = error
                    } else {
                        errorStatus = "connection err: \(outPutString ?? "CE")"
                    }
                }
            }
        }
        
        sharedObj.handler = { s in
            self.iosString = s
        }
        
        healthKitObject.updateError = { errorValue in
            DispatchQueue.main.async {
                errorStatus = errorValue ?? ""
            }
        }
        
        sharedObj.startWorkout = {
            healthKitObject.selectedWorkout = .running
        }
    }
    
    
    func testingMethod() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timeObejct in
            DispatchQueue.main.async {
                value = (50...100).randomElement()!
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(LFHealthKitManager())
    }
}
