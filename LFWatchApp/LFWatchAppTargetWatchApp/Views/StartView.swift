//
//  StartView.swift
//  LFConnectWatch Watch App
//
//  Created by Ravikiran Gajula on 6/3/23.
//  Copyright © 2023 Life Fitness. All rights reserved.
//

import SwiftUI
import HealthKit

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.scenePhase) var scenePhase
    
    private var workoutTypes: [HKWorkoutActivityType] = [.climbing, .walking, .running, .cycling, .rowing, .highIntensityIntervalTraining, .flexibility, .mixedCardio, .elliptical]
    private let wcManagerObj = WatchConnectManager.shared
    
    @State var isActive = false
    @State var stateChange = ""

    var body: some View {
        ZStack {
            VStack(spacing: 10){
                Image("App_logo")
                    .clipShape(Capsule())
                Text(workoutManager.statusText)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("PrimaryTextColor"))
                Text(self.stateChange)
            }
            NavigationLink(destination:
                            SessionPagingView(),
                           isActive: self.$isActive) {
            }
            .hidden()
            .onAppear {
                workoutManager.updateAuthorizationStatus()
                workoutManager.requestAuthorization {sucess, error in
                    if sucess {
                        workoutManager.sharedObj.send("START NOW") { outPutString in
                            print("error == \(outPutString)")
                        }
                    }
                }
                watchConnectionManagerCallBacks()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                self.stateChange = "Inactive"
            } else if newPhase == .active {
                workoutManager.updateAuthorizationStatus()
            } else if newPhase == .background {
                self.stateChange = "background"
            }
        }
    }
    
}

extension StartView {
    
    private func watchConnectionManagerCallBacks() {
        if workoutManager.endWorkoutSelected == false {
            wcManagerObj.startWorkoutWithSelectedActivity = { workoutype in
                switch workoutype.rawValue {
                case 9:
                    workoutManager.selectedWorkout = .climbing
                case 11:
                    workoutManager.selectedWorkout = .crossTraining
                case 13:
                    workoutManager.selectedWorkout = .cycling
                case 16:
                    workoutManager.selectedWorkout = .elliptical
                case 35:
                    workoutManager.selectedWorkout = .rowing
                case 37:
                    workoutManager.selectedWorkout = .running
                case 53:
                    workoutManager.selectedWorkout = .walking
                case 62:
                    workoutManager.selectedWorkout = .flexibility
                case 63:
                    workoutManager.selectedWorkout = .highIntensityIntervalTraining
                case 73:
                    workoutManager.selectedWorkout = .mixedCardio
                    
                default:
                    workoutManager.selectedWorkout = .walking
                }
                isActive = true
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView().environmentObject(WorkoutManager())
    }
}

extension HKWorkoutActivityType: Identifiable {
    
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
        case .running:
            return " GPS Run"
        case .cycling:
            return "GPS Bike"
        case .walking:
            return "GPS Walk"
        case .rowing:
            return "Rowing"
        case .elliptical:
            return "Elliptical"
        case .highIntensityIntervalTraining:
            return "HIT"
        case .mixedCardio:
            return "Strength"
        case .climbing:
            return "Climb"
        case .flexibility:
            return "Flexibility"
        default:
            return "UnKnown"
        }
    }
}
