import SwiftUI

struct OverallStatusWidget: View {
    let monitoringService: MonitoringService
    var totalDevices: Int = 0
    var onlineDevices: Int = 0
    var servers: Int = 0
    var services: Int = 0
    var vms: Int = 0
    
    private var hasDevice: Bool {
        monitoringService.deviceMonitor != nil
    }
    
    private var activeTypes: Int {
        var count = 0
        if hasDevice { count += 1 }
        if servers > 0 { count += 1 }
        if services > 0 { count += 1 }
        if vms > 0 { count += 1 }
        return count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overall Status")
                    .font(.headline)
                Spacer()
                StatusIndicator(status: monitoringService.overallStatus)
            }
            
            if totalDevices > 0 {
                Text("\(onlineDevices)/\(totalDevices) Devices Online")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: activeTypes > 3 ? 8 : 16) {
                    if hasDevice {
                        if activeTypes > 3 {
                            Image(systemName: "iphone")
                                .foregroundColor(.secondary)
                        } else {
                            Label("1 Device", systemImage: "iphone")
                        }
                    }
                    
                    if servers > 0 {
                        if activeTypes > 3 {
                            Image(systemName: "server.rack")
                                .foregroundColor(.secondary)
                        } else {
                            Label("\(servers) Servers", systemImage: "server.rack")
                        }
                    }
                    
                    if services > 0 {
                        if activeTypes > 3 {
                            Image(systemName: "gear")
                                .foregroundColor(.secondary)
                        } else {
                            Label("\(services) Services", systemImage: "gear")
                        }
                    }
                    
                    if vms > 0 {
                        if activeTypes > 3 {
                            Image(systemName: "cpu")
                                .foregroundColor(.secondary)
                        } else {
                            Label("\(vms) VMs", systemImage: "cpu")
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
} 