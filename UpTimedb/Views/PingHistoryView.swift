import SwiftUI
import Charts

struct PingHistoryView: View {
    let monitoringService: MonitoringService
    
    let timeRanges = [
        ("Last 15 Minutes", 15 * 60),
        ("Last Hour", 60 * 60),
        ("Last 8 Hours", 8 * 60 * 60),
        ("Last 24 Hours", 24 * 60 * 60)
    ]
    
    func pingColor(_ ping: Double) -> Color {
        if ping > 200 { return .red }
        else if ping > 100 { return .orange }
        else { return .green }
    }
    
    var body: some View {
        List {
            ForEach(timeRanges, id: \.0) { title, seconds in
                Section(header: Text(title)) {
                    Chart {
                        ForEach(monitoringService.getPingHistory(forLast: seconds), id: \.timestamp) { ping in
                            BarMark(
                                x: .value("Time", ping.timestamp, unit: .second),
                                y: .value("Ping", ping.value)
                            )
                            .foregroundStyle(pingColor(ping.value))
                        }
                    }
                    .frame(height: 100)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date.formatted(.dateTime.hour().minute()))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
        .navigationTitle("Ping History")
    }
} 