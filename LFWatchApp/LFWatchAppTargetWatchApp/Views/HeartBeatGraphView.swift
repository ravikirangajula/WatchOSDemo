//
//  HeartBeatGraphView.swift
//  LFconnect
//
//  Created by Ravikiran Gajula on 24/3/23.
//  Copyright © 2023 Life Fitness. All rights reserved.
//

import SwiftUI
import HealthKit
import Charts

@available(watchOS 9.0, *)
struct HeartBeatGraphView: View {
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    private let yValues = stride(from: 0, to: 300, by: 40).map { $0 }
    
    @State var stateChange = ""
    @State private var endWorkoutObserved = false {
        didSet {
            if endWorkoutObserved == true {
                dismiss()
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .lastTextBaseline) {
                Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))))
                Text("BPM")
                Spacer()
                Text(stateChange)
            }.padding(.leading, 16)
            Chart(workoutManager.data) { details in
                LineMark(
                    x: .value("Time", details.heartBeat.time, unit: .second),
                    y: .value("Heart Beat", details.heartBeat.beat)
                ).lineStyle(.init(lineWidth: 4))
                    .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: yValues) { value in
                    if value.index % 2 == 0 {
                        AxisValueLabel()
                    }
                }
            }
            .foregroundStyle(.linearGradient(colors: [Color("LineGraphColor"), .red, Color("LineGraphColor")], startPoint: .leading, endPoint: .trailing))
        }
        .onReceive(workoutManager.$endWorkoutSelected) { self.endWorkoutObserved = $0 }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                self.stateChange = "Inactive"
            } else if newPhase == .active {
                self.stateChange = "Active"
            } else if newPhase == .background {
                self.stateChange = "background"
            }
        }
    }
}

@available(watchOS 9.0, *)
struct HeartBeatGraphView_Previews: PreviewProvider {
    static var previews: some View {
        HeartBeatGraphView().environmentObject(WorkoutManager())
    }
}
