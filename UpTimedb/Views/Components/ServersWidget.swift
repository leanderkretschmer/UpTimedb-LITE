import SwiftUI
import Charts

struct ServersListWidget: View {
    let servers: [Server]
    let services: [Service]
    @ObservedObject var monitoringService: MonitoringService
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(servers) { server in
                ServerCardView(server: server, services: services, monitoringService: monitoringService)
                    .frame(maxWidth: horizontalSizeClass == .regular ? nil : .infinity)
            }
        }
    }
}

struct ServerCardView: View {
    let server: Server
    let services: [Service]
    @ObservedObject var monitoringService: MonitoringService
    @AppStorage("showAdvancedInfo") private var showAdvancedInfo: Bool = false
    
    private var servicesOnServer: [Service] {
        services.filter { $0.serverId == server.id }
    }
    
    private var vmsOnServer: [VirtualMachine] {
        monitoringService.virtualMachines.filter { $0.parentServerId == server.id }
    }
    
    var body: some View {
        NavigationLink(destination: ServerDetailView(server: server, services: services, monitoringService: monitoringService)) {
            VStack(alignment: .leading, spacing: 8) {
                if monitoringService.isSimulated {
                    Label("Simulated Data", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                HStack {
                    Text(server.name)
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    StatusIndicator(status: server.status)
                }
                
                Text(server.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if showAdvancedInfo {
                    HStack {
                        Label(server.type, systemImage: server.type == "Physical" ? "server.rack" : "cloud")
                        Spacer()
                        Label(server.location, systemImage: "building.2")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Label("\(servicesOnServer.count) Services", systemImage: "gear")
                    Label("\(vmsOnServer.count) VMs", systemImage: "cpu")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Chart {
                    ForEach(Array(server.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(server.status.color)
                    }
                }
                .frame(height: 100)
                
                Text("Current Ping: \(Int(server.lastPing))ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if showAdvancedInfo {
                    ResourceGauge(title: "CPU", value: server.resources.cpuUsage, systemImage: "cpu")
                    ResourceGauge(title: "Memory", value: server.resources.memoryUsage, systemImage: "memorychip")
                    
                    ForEach(server.resources.drives) { drive in
                        ResourceGauge(
                            title: "Storage (\(drive.name))",
                            value: drive.usagePercentage,
                            systemImage: "externaldrive"
                        )
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
} 