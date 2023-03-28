/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The workout metrics view.
*/

import SwiftUI
import HealthKit
import Charts

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    // MARK: Properties
    let yValues = stride(from: 40, to: 220, by: 20).map { $0 }

    // MARK: Body
    var body: some View {
        if #available(watchOS 9,*) {
            VStack(alignment: .leading){
                HStack(alignment: .lastTextBaseline) {
                    Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))))
                        .font(Font.custom("Roboto-Bold", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0).opacity(1))
                    Text("BPM")
                        .font(Font.custom("Roboto-Bold", size: 16))
                        .foregroundColor(Color(red: 209.0/255.0, green: 211.0/255.0, blue: 212.0/255.0).opacity(1))
                }
                Chart(workoutManager.data) { person in
                    LineMark(
                        x: .value("Time", person.heartBeat.time, unit: .second),
                        y: .value("Heart Beat", person.heartBeat.beat)
                    ).lineStyle(.init(lineWidth: 4))
                        .interpolationMethod(.cardinal)
                }//.chartYScale(domain: 10...200)
                .chartXAxis(.hidden)
                .chartYAxis{
                    AxisMarks(position: .trailing, values: yValues)
                }
                .foregroundStyle(Color(red: 209.0/255.0, green: 31.0/255.0, blue: 46.0/255.0).opacity(1.0).gradient)
                .padding(.horizontal, 2)
            }
        } else {
            TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
                                                 isPaused: workoutManager.session?.state == .paused)) { context in
                VStack(alignment: .leading) {
                    ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                        .foregroundStyle(.yellow)
                    Text(Measurement(value: workoutManager.activeEnergy, unit: UnitEnergy.kilocalories)
                            .formatted(.measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))))
                    Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                    Text(Measurement(value: workoutManager.distance, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road)))
                }
                .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
                .frame(maxWidth: .infinity, alignment: .leading)
                .ignoresSafeArea(edges: .bottom)
                .scenePadding()
            }
            
        }
  
    }

    
//    var body: some View {
//        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
//                                             isPaused: workoutManager.session?.state == .paused)) { context in
//            VStack(alignment: .leading) {
//                ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
//                    .foregroundStyle(.yellow)
//                Text(Measurement(value: workoutManager.activeEnergy, unit: UnitEnergy.kilocalories)
//                        .formatted(.measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))))
//                Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
//                Text(Measurement(value: workoutManager.distance, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road)))
//            }
//            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .ignoresSafeArea(edges: .bottom)
//            .scenePadding()
//        }
//    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricsView().environmentObject(WorkoutManager())
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    var isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
                                                    by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
            .entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            guard !isPaused else { return nil }
            return baseSchedule.next()
        }
    }
}
