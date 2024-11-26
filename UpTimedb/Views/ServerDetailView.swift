import SwiftUI
import Charts

struct ServerDetailView: View {
    let server: Server
    let services: [Service]
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        List {
            StatusSection(server: server)
            ResourcesSection(resources: server.resources)
            StorageSection(drives: server.resources.drives)
            PingHistorySection(server: server)
            ServicesSection(services: services.filter { $0.serverId == server.id }, server: server)
            NotificationSettingsSection(server: server, monitoringService: monitoringService)
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sections
private struct StatusSection: View {
    let server: Server
    
    var body: some View {
        Section("Status") {
            HStack {
                Text("Current Status")
                Spacer()
                StatusIndicator(status: server.status)
            }
            
            HStack {
                Text("Current Ping")
                Spacer()
                Text("\(Int(server.lastPing))ms")
            }
        }
    }
}

private struct ResourcesSection: View {
    let resources: SystemResources
    
    var body: some View {
        Section("System Resources") {
            ResourceGauge(title: "CPU", value: resources.cpuUsage, systemImage: "cpu")
            ResourceGauge(title: "RAM", value: resources.ramUsage, systemImage: "memorychip")
            ResourceGauge(title: "GPU", value: resources.gpuUsage, systemImage: "gpu")
            ResourceGauge(title: "Network", value: resources.networkUsage, systemImage: "network")
        }
    }
}

private struct StorageSection: View {
    let drives: [DriveInfo]
    
    var body: some View {
        Section("Storage") {
            ForEach(drives) { drive in
                VStack(alignment: .leading) {
                    Text(drive.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(drive.usedSpace))GB used of \(Int(drive.totalSpace))GB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(drive.freeSpace))GB free")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: drive.usagePercentage, total: 100)
                        .tint(drive.usagePercentage > 90 ? .red : 
                              drive.usagePercentage > 75 ? .orange : .blue)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct PingHistorySection: View {
    let server: Server
    
    var body: some View {
        Section("Ping History") {
            Chart {
                ForEach(Array(server.pingHistory.enumerated()), id: \.offset) { index, ping in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Ping", ping)
                    )
                    .foregroundStyle(server.status.color)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .padding(.vertical)
        }
    }
}

private struct ServicesSection: View {
    let services: [Service]
    let server: Server
    
    var body: some View {
        Section("Services") {
            ForEach(services) { service in
                NavigationLink {
                    ServiceDetailView(service: service, server: server)
                } label: {
                    HStack {
                        Text(service.name)
                        Spacer()
                        StatusIndicator(status: service.status)
                    }
                }
            }
        }
    }
}

private struct NotificationSettingsSection: View {
    let server: Server
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        Section("Notification Settings") {
            Toggle("Notify When Offline", isOn: .init(
                get: { server.notificationSettings.notifyOnOffline },
                set: { monitoringService.updateServerNotificationSetting(serverId: server.id, notifyOnOffline: $0) }
            ))
            
            Toggle("Notify on Storage Warning", isOn: .init(
                get: { server.notificationSettings.notifyOnStorageWarning },
                set: { monitoringService.updateServerNotificationSetting(serverId: server.id, notifyOnStorageWarning: $0) }
            ))
            
            if server.notificationSettings.notifyOnStorageWarning {
                HStack {
                    Text("Warning Threshold")
                    Spacer()
                    Text("\(Int(server.notificationSettings.storageWarningThreshold))%")
                }
                
                Slider(value: .init(
                    get: { server.notificationSettings.storageWarningThreshold },
                    set: { monitoringService.updateServerNotificationSetting(serverId: server.id, storageThreshold: $0) }
                ), in: 50...95, step: 5)
            }
        }
    }
}

struct ResourceGauge: View {
    let title: String
    let value: Double
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                Spacer()
                Text("\(Int(value))%")
                    .foregroundStyle(.secondary)
            }
            
            Gauge(value: value, in: 0...100) {
                EmptyView()
            }
            .tint(value > 90 ? .red :
                  value > 75 ? .orange : .blue)
        }
    }
} 
