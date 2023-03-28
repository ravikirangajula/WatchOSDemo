//
//  SessionPagingView.swift
//  LFConnectWatch Watch App
//
//  Created by Ravikiran Gajula on 6/3/23.
//  Copyright © 2023 Life Fitness. All rights reserved.
//

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var selection: Tab = .metrics

    enum Tab {
        case controls, metrics, nowPlaying, graphView
    }

    var body: some View {
        TabView(selection: $selection) {
           // ControlsView().tag(Tab.controls)
            if #available(watchOS 9.0, *) {
                HeartBeatGraphView().tag(Tab.graphView)
            } else {
                MetricsView().tag(Tab.metrics)
            }
           // NowPlayingView().tag(Tab.nowPlaying)
        }
        .navigationTitle(workoutManager.selectedWorkout?.name ?? "")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(selection == .nowPlaying)
        .onChange(of: workoutManager.running) { _ in
            displayMetricsView()
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic))
        .onChange(of: isLuminanceReduced) { _ in
            displayMetricsView()
        }
    }

    private func displayMetricsView() {
        withAnimation {
            if #available(watchOS 9.0, *) {
                selection = .graphView
            } else {
                selection = .metrics
            }
        }
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPagingView().environmentObject(WorkoutManager())
    }
}
