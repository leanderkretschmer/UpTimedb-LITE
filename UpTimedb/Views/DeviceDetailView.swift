import SwiftUI
import Charts

struct DeviceDetailView: View {
    let device: DeviceMonitor
    
    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Device Status")
                    Spacer()
                    StatusIndicator(status: device.status)
                }
                
                HStack {
                    Text("Device Name")
                    Spacer()
                    Text(device.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("IP Address")
                    Spacer()
                    Text(device.ipAddress)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Ping Time")
                    Spacer()
                    Text("\(Int(device.lastPing))ms")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Resources") {
                Text("Resource monitoring currently unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                ResourceGauge(title: "CPU Usage", value: device.resources.cpuUsage, systemImage: "cpu")
                    .opacity(0.5)
                ResourceGauge(title: "Memory Usage", value: device.resources.memoryUsage, systemImage: "memorychip")
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
            
            Section("Response Time History") {
                Chart {
                    ForEach(Array(device.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(device.status.color)
                    }
                }
                .frame(height: 200)
            }
        }
        .navigationTitle("Device Monitor")
    }
} 