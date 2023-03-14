//
//  LFWatchAppTargetApp.swift
//  LFWatchAppTarget Watch App
//
//  Created by Ravikiran Gajula on 14/2/23.
//

import SwiftUI


@main
struct LFWatchAppTarget_Watch_AppApp: App {
    
    @StateObject private var workoutManager = WorkoutManager()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView) {
                SummaryView()
            }
            .environmentObject(workoutManager)
        }
    }

 /*   var body: some Scene {
        WindowGroup {
            ContentView()
        }
    } */
    
}
