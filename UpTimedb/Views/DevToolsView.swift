import SwiftUI

struct DevToolsView: View {
    @ObservedObject var monitoringService: MonitoringService
    @State private var showDebugInfo = false
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    
    var body: some View {
        Form {
            Section(header: Text("Debug Information")) {
                Toggle("Show Debug Information", isOn: $showDebugInfo)
                
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Servers: \(monitoringService.servers.count)")
                        Text("Services: \(monitoringService.services.count)")
                        Text("VMs: \(monitoringService.virtualMachines.count)")
                        Text("Overall Status: \(monitoringService.overallStatus.rawValue)")
                        
                        if monitoringService.isDeepTesting {
                            ProgressView("Deep Test Progress", value: monitoringService.deepTestProgress, total: 1.0)
                                .progressViewStyle(.linear)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Testing Tools")) {
                Button(action: {
                    if monitoringService.isDeepTesting {
                        monitoringService.stopDeepTest()
                    } else {
                        monitoringService.startDeepTest()
                    }
                }) {
                    Text(monitoringService.isDeepTesting ? "Stop Deep Testing" : "Start Deep Testing")
                        .foregroundColor(monitoringService.isDeepTesting ? .red : .blue)
                }
                
                if monitoringService.isDeepTesting {
                    Text("Running comprehensive system tests...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    monitoringService.setupMockData()
                }) {
                    Text("Regenerate Test Data")
                }
            }
            
            Section(header: Text("Data Management")) {
                Button(action: {
                    showResetConfirmation = true
                }) {
                    Text("Reset All Settings")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    exportDebugData()
                }) {
                    Text("Export Debug Data")
                }
            }
            
            Section(header: Text("Links")) {
                Link("Source Code", destination: URL(string: "https://github.com/yourusername/UpTimedb")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/yourusername/UpTimedb/issues")!)
            }
            
            Section(header: Text("Version Information")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Developer Tools")
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: [generateDebugReport()])
        }
    }
    
    private func resetAllSettings() {
        // ... existing reset code ...
    }
    
    private func generateDebugReport() -> String {
        var report = "UpTimedb Debug Report\n"
        report += "===================\n\n"
        
        // Add system information
        report += "System Status\n"
        report += "--------------\n"
        report += "Overall Status: \(monitoringService.overallStatus.rawValue)\n"
        report += "Simulation Enabled: \(monitoringService.isSimulated)\n\n"
        
        // Add server information
        report += "Servers (\(monitoringService.servers.count))\n"
        report += "------------------------\n"
        for server in monitoringService.servers {
            report += "- \(server.name): \(server.status.rawValue)\n"
            report += "  IP: \(server.ipAddress)\n"
            report += "  Ping: \(Int(server.lastPing))ms\n"
            report += "  CPU: \(Int(server.resources.cpuUsage))%\n"
            report += "  Memory: \(Int(server.resources.memoryUsage))%\n\n"
        }
        
        // Add service information
        report += "Services (\(monitoringService.services.count))\n"
        report += "-------------------------\n"
        for service in monitoringService.services {
            report += "- \(service.name): \(service.status.rawValue)\n"
            report += "  Ping: \(Int(service.lastPing))ms\n\n"
        }
        
        // Add VM information
        report += "Virtual Machines (\(monitoringService.virtualMachines.count))\n"
        report += "----------------------------------------\n"
        for vm in monitoringService.virtualMachines {
            report += "- \(vm.name): \(vm.status.rawValue)\n"
            report += "  IP: \(vm.ipAddress)\n"
            report += "  Ping: \(Int(vm.lastPing))ms\n"
            report += "  CPU: \(Int(vm.resources.cpuUsage))%\n"
            report += "  Memory: \(Int(vm.resources.memoryUsage))%\n\n"
        }
        
        // Add device monitoring information if enabled
        if let device = monitoringService.deviceMonitor {
            report += "Local Device Monitoring\n"
            report += "----------------------\n"
            report += "Device: \(device.name)\n"
            report += "Status: \(device.status.rawValue)\n"
            report += "IP: \(device.ipAddress)\n"
            report += "Ping: \(Int(device.lastPing))ms\n\n"
        }
        
        return report
    }
    
    private func exportDebugData() {
        showExportSheet = true
    }
} 