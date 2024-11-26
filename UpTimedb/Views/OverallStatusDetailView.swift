import SwiftUI
import Charts

struct OverallStatusDetailView: View {
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        List {
            Section("Overall Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    StatusIndicator(status: monitoringService.overallStatus)
                }
                
                HStack {
                    Text("Average Ping")
                    Spacer()
                    Text("\(Int(calculateAveragePing()))ms")
                }
                
                HStack {
                    Text("Active Services")
                    Spacer()
                    Text("\(monitoringService.services.filter { $0.status != .offline }.count) of \(monitoringService.services.count)")
                }
            }
            
            Section("System Health") {
                Chart {
                    let avgPings = calculateAveragePingHistory()
                    ForEach(Array(avgPings.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(monitoringService.overallStatus.color)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .padding(.vertical)
            }
            
            if !offlineServices.isEmpty {
                Section("Current Issues") {
                    ForEach(offlineServices) { service in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text(service.name)
                                Text("Running on \(serverName(for: service))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Offline")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Section("Storage Warnings") {
                ForEach(serversWithStorageWarnings, id: \.0.id) { server, drive in
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(server.name)
                            Text("\(drive.name) - \(Int(drive.usagePercentage))% used")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("System Overview")
    }
    
    private var offlineServices: [Service] {
        monitoringService.services.filter { $0.status == .offline }
    }
    
    private var serversWithStorageWarnings: [(Server, DriveInfo)] {
        var warnings: [(Server, DriveInfo)] = []
        for server in monitoringService.servers {
            for drive in server.resources.drives {
                if drive.usagePercentage > 75 {
                    warnings.append((server, drive))
                }
            }
        }
        return warnings
    }
    
    private func serverName(for service: Service) -> String {
        monitoringService.servers.first { $0.id == service.serverId }?.name ?? "Unknown Server"
    }
    
    private func calculateAveragePing() -> Double {
        let onlineServices = monitoringService.services.filter { $0.status != .offline }
        guard !onlineServices.isEmpty else { return 0 }
        return onlineServices.reduce(0.0) { $0 + $1.lastPing } / Double(onlineServices.count)
    }
    
    private func calculateAveragePingHistory() -> [Double] {
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