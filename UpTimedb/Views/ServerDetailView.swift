import SwiftUI
import Charts

struct ServerDetailView: View {
    let server: Server
    let services: [Service]
    @ObservedObject var monitoringService: MonitoringService
    
    private var servicesOnServer: [Service] {
        services.filter { $0.serverId == server.id }
    }
    
    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    StatusIndicator(status: server.status)
                }
                
                HStack {
                    Text("Response Time")
                    Spacer()
                    Text("\(Int(server.lastPing))ms")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Resources") {
                ResourceGauge(title: "CPU Usage", value: server.resources.cpuUsage, systemImage: "cpu")
                ResourceGauge(title: "Memory Usage", value: server.resources.memoryUsage, systemImage: "memorychip")
                
                ForEach(server.resources.drives) { drive in
                    ResourceGauge(
                        title: "Storage (\(drive.name))",
                        value: drive.usagePercentage,
                        systemImage: "externaldrive"
                    )
                }
            }
            
            Section("Services") {
                ForEach(servicesOnServer) { service in
                    NavigationLink(destination: ServiceDetailView(service: service, server: server)) {
                        HStack {
                            Text(service.name)
                            Spacer()
                            StatusIndicator(status: service.status)
                        }
                    }
                }
            }
            
            Section("Response Time History") {
                Chart {
                    ForEach(Array(server.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(server.status.color)
                    }
                }
                .frame(height: 200)
            }
            
            Section("Notification Settings") {
                Toggle("Notify When Offline", isOn: Binding(
                    get: { server.notificationSettings.notifyOnOffline },
                    set: { newValue in
                        monitoringService.updateServerNotificationSetting(
                            serverId: server.id,
                            notifyOnOffline: newValue
                        )
                    }
                ))
                
                Toggle("Storage Warning", isOn: Binding(
                    get: { server.notificationSettings.notifyOnStorageWarning },
                    set: { newValue in
                        monitoringService.updateServerNotificationSetting(
                            serverId: server.id,
                            notifyOnStorageWarning: newValue
                        )
                    }
                ))
                
                if server.notificationSettings.notifyOnStorageWarning {
                    Text("Will notify when storage usage exceeds \(Int(server.notificationSettings.storageWarningThreshold))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(server.name)
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
