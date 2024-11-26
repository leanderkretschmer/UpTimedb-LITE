import SwiftUI
import Charts

struct OverallStatusWidget: View {
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Status")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                StatusIndicator(status: monitoringService.overallStatus)
            }
            
            // Single line chart showing average ping
            Chart {
                let avgPing = calculateAveragePing()
                if !avgPing.isEmpty {
                    ForEach(Array(avgPing.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(monitoringService.overallStatus.color.opacity(0.8))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXScale(domain: 0...30)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text("\(value.index * 20)ms")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .frame(height: 200)
            .padding(.vertical, 8)
            
            if !monitoringService.services.filter({ $0.status == .offline }).isEmpty {
                issuesView
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var issuesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Issues")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            ForEach(Array(monitoringService.services.filter { $0.status == .offline }.prefix(3))) { service in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("\(service.name) is offline")
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func calculateAveragePing() -> [Double] {
        let onlineServices = monitoringService.services.filter { $0.status != .offline }
        guard !onlineServices.isEmpty else { return [] }
        
        var avgPings: [Double] = []
        let maxPoints = min(30, onlineServices.first?.pingHistory.count ?? 0)
        
        for i in 0..<maxPoints {
            let sum = onlineServices.reduce(0.0) { total, service in
                total + (i < service.pingHistory.count ? service.pingHistory[i] : 0)
            }
            avgPings.append(sum / Double(onlineServices.count))
        }
        
        return avgPings
    }
} 