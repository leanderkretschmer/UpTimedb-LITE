import SwiftUI
import Charts

struct DeviceWidget: View {
    let device: DeviceMonitor
    @AppStorage("showAdvancedInfo") private var showAdvancedInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(device.name)
                    .font(.subheadline)
                    .bold()
                Spacer()
                StatusIndicator(status: device.status)
            }
            
            Text(device.ipAddress)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(Array(device.pingHistory.enumerated()), id: \.offset) { index, ping in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Ping", ping)
                    )
                    .foregroundStyle(device.status.color)
                }
            }
            .frame(height: 100)
            
            Text("Current Ping: \(Int(device.lastPing))ms")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showAdvancedInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Resource Monitoring Unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    
                    ResourceGauge(title: "CPU", value: device.resources.cpuUsage, systemImage: "cpu")
                        .opacity(0.5)
                    ResourceGauge(title: "Memory", value: device.resources.memoryUsage, systemImage: "memorychip")
                        .opacity(0.5)
                    
                    ForEach(device.resources.drives) { drive in
                        ResourceGauge(
                            title: "Storage (\(drive.name))",
                            value: drive.usagePercentage,
                            systemImage: "externaldrive"
                        )
                        .opacity(0.5)
                    }
                }
                .overlay {
                    Text("Resource monitoring currently unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(8)
    }
} 