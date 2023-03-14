/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The start view.
*/

import SwiftUI
import HealthKit

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var workoutTypes: [HKWorkoutActivityType] = [.cycling, .running, .walking]
    private let wcManagerObj = WatchConnectManager.shared
    @State var isActive = false
    @State var workoutType: HKWorkoutActivityType = .walking
    
    var body: some View {
            VStack {
                NavigationLink("Start",
                               destination: SessionPagingView(),
                               tag: .walking,
                               selection: $workoutManager.selectedWorkout)
//                Button("Click") {
//                    isActive = true
//                    watchConnectionManagerCallBacks()
//                }
                NavigationLink(destination:
                                SessionPagingView(),
                               isActive: self.$isActive) {
                    EmptyView()
                }.hidden()
            }
            .navigationTitle("Workouts")
            .onAppear {
                workoutManager.requestAuthorization()
                watchConnectionManagerCallBacks()
            }
    }
}

extension StartView {
    
    private func watchConnectionManagerCallBacks() {

        wcManagerObj.startWorkout = {
            self.workoutManager.selectedWorkout = .cycling
            isActive = true
        }
        
        wcManagerObj.endWorkout = {
            //healthKitObject.endWorkout()
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
            return "Run"
        case .cycling:
            return "Bike"
        case .walking:
            return "Walk"
        default:
            return ""
        }
    }
}
