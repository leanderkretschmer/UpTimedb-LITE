import SwiftUI
import Charts

struct VMsWidget: View {
    let vms: [VirtualMachine]
    let servers: [Server]
    @ObservedObject var monitoringService: MonitoringService
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(vms) { vm in
                if let server = servers.first(where: { $0.id == vm.parentServerId }) {
                    VMCard(vm: vm, server: server, monitoringService: monitoringService)
                        .frame(maxWidth: horizontalSizeClass == .regular ? nil : .infinity)
                }
            }
        }
    }
}

struct VMCard: View {
    let vm: VirtualMachine
    let server: Server
    @AppStorage("showAdvancedInfo") private var showAdvancedInfo: Bool = false
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        NavigationLink(destination: VMDetailView(vm: vm, server: server)) {
            VStack(alignment: .leading, spacing: 8) {
                if monitoringService.isSimulated {
                    Label("Simulated Data", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                HStack {
                    Text(vm.name)
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    StatusIndicator(status: vm.status)
                }
                
                Text("Host: \(server.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(vm.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(Array(vm.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(vm.status.color)
                    }
                }
                .frame(height: 100)
                
                Text("Current Ping: \(Int(vm.lastPing))ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if showAdvancedInfo {
                    ResourceGauge(title: "CPU", value: vm.resources.cpuUsage, systemImage: "cpu")
                    ResourceGauge(title: "Memory", value: vm.resources.memoryUsage, systemImage: "memorychip")
                    
                    ForEach(vm.resources.drives) { drive in
                        ResourceGauge(
                            title: "Storage (\(drive.name))",
                            value: drive.usagePercentage,
                            systemImage: "externaldrive"
                        )
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct VMDetailView: View {
    let vm: VirtualMachine
    let server: Server
    
    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    StatusIndicator(status: vm.status)
                }
                
                HStack {
                    Text("IP Address")
                    Spacer()
                    Text(vm.ipAddress)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Parent Server")
                    Spacer()
                    Text(server.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Response Time")
                    Spacer()
                    Text("\(Int(vm.lastPing))ms")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Resources") {
                ResourceGauge(title: "CPU Usage", value: vm.resources.cpuUsage, systemImage: "cpu")
                ResourceGauge(title: "Memory Usage", value: vm.resources.memoryUsage, systemImage: "memorychip")
                
                ForEach(vm.resources.drives) { drive in
                    ResourceGauge(
                        title: "Storage (\(drive.name))",
                        value: drive.usagePercentage,
                        systemImage: "externaldrive"
                    )
                }
            }
            
            Section("Response Time History") {
                Chart {
                    ForEach(Array(vm.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(vm.status.color)
                    }
                }
                .frame(height: 200)
            }
        }
        .navigationTitle(vm.name)
    }
}

#Preview {
    let server = Server(
        id: UUID(),
        name: "Test Server",
        status: .online,
        pingHistory: Array(repeating: 25.0, count: 30),
        lastPing: 25.0,
        resources: .mockResources(),
        notificationSettings: ServerNotificationSettings(),
        ipAddress: "192.168.0.1",
        location: "Data Center 1",
        type: "Physical"
    )
    
    let vm = VirtualMachine(
        id: UUID(),
        name: "VM-1",
        status: .online,
        resources: SystemResources(
            cpuUsage: 45.0,
            memoryUsage: 60.0,
            drives: [
                DriveInfo(name: "System", totalSpace: 512, usedSpace: 384),
                DriveInfo(name: "Data", totalSpace: 1024, usedSpace: 768)
            ]
        ),
        lastPing: 25.0,
        pingHistory: Array(repeating: 25.0, count: 30),
        ipAddress: "192.168.1.100",
        parentServerId: server.id
    )
    
    VMsWidget(vms: [vm], servers: [server], monitoringService: MonitoringService())
} 