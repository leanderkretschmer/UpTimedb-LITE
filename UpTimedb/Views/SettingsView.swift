import SwiftUI

struct SettingsView: View {
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    @AppStorage("simulationEnabled") private var simulationEnabled: Bool = true
    @AppStorage("simulateDowntime") private var simulateDowntime: Bool = false
    @AppStorage("simulateWarnings") private var simulateWarnings: Bool = false
    @AppStorage("dynamicAppIcon") private var dynamicAppIcon: Bool = true
    @AppStorage("backgroundMonitoringEnabled") private var backgroundMonitoringEnabled: Bool = false
    @AppStorage("backgroundCheckInterval") private var backgroundCheckInterval: Double = 300
    @AppStorage("simulatedServers") private var simulatedServers: Int = 2
    @AppStorage("simulatedServices") private var simulatedServices: Int = 4
    @AppStorage("simulatedVMs") private var simulatedVMs: Int = 2
    @AppStorage("showAdvancedInfo") private var showAdvancedInfo: Bool = false
    @ObservedObject var monitoringService: MonitoringService
    @State private var isTestingNotification = false
    @State private var testCountdown = 10
    @State private var showResetConfirmation = false
    @State private var showDebugInfo = false
    @State private var showExportSheet = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    
    private let intervalOptions: [(String, Double)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600)
    ]
    
    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                TextField("API Endpoint", text: $apiEndpoint)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("Monitoring")) {
                Toggle("Background Monitoring", isOn: $backgroundMonitoringEnabled)
                    .onChange(of: backgroundMonitoringEnabled) { newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
                
                if backgroundMonitoringEnabled {
                    Picker("Check Interval", selection: $backgroundCheckInterval) {
                        ForEach(intervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    
                    Text("App will check status every \(formatInterval(backgroundCheckInterval))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Simulation Settings")) {
                Toggle("Enable Simulation", isOn: $simulationEnabled)
                
                if simulationEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Components")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Servers: \(simulatedServers)")
                                Spacer()
                                Text("\(simulatedServers)")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: .init(
                                get: { Double(simulatedServers) },
                                set: { simulatedServers = Int($0) }
                            ), in: 1...8, step: 1)
                            .onChange(of: simulatedServers) { oldValue, newValue in
                                monitoringService.setupMockData()
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Services: \(simulatedServices)")
                                Spacer()
                                Text("\(simulatedServices)")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: .init(
                                get: { Double(simulatedServices) },
                                set: { simulatedServices = Int($0) }
                            ), in: 1...12, step: 1)
                            .onChange(of: simulatedServices) { oldValue, newValue in
                                monitoringService.setupMockData()
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Virtual Machines: \(simulatedVMs)")
                                Spacer()
                                Text("\(simulatedVMs)")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: .init(
                                get: { Double(simulatedVMs) },
                                set: { simulatedVMs = Int($0) }
                            ), in: 1...6, step: 1)
                            .onChange(of: simulatedVMs) { oldValue, newValue in
                                monitoringService.setupMockData()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Simulation Scenarios")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Toggle(isOn: $simulateDowntime) {
                            Label("Simulate Downtime", systemImage: "exclamationmark.triangle")
                        }
                        .onChange(of: simulateDowntime) { oldValue, newValue in
                            monitoringService.updateSimulationSettings()
                        }
                        
                        Toggle(isOn: $simulateWarnings) {
                            Label("Simulate Warnings", systemImage: "exclamationmark.circle")
                        }
                        .onChange(of: simulateWarnings) { oldValue, newValue in
                            monitoringService.updateSimulationSettings()
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Text("Using simulated data for testing purposes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dynamic App Icon", isOn: $dynamicAppIcon)
                    .onChange(of: dynamicAppIcon) { newValue in
                        monitoringService.updateAppIcon()
                    }
                
                if dynamicAppIcon {
                    Text("App icon will change to reflect system status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Use System Theme", isOn: $colorSchemeManager.useSystemColorScheme)
                
                if !colorSchemeManager.useSystemColorScheme {
                    Toggle("Dark Mode", isOn: $colorSchemeManager.isDarkMode)
                }
            }
            
            Section(header: Text("Debug Tools")) {
                Toggle("Show Debug Information", isOn: $showDebugInfo)
                
                if showDebugInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Servers: \(monitoringService.servers.count)")
                        Text("Services: \(monitoringService.services.count)")
                        Text("VMs: \(monitoringService.virtualMachines.count)")
                        Text("Overall Status: \(monitoringService.overallStatus.rawValue)")
                        Text("Background Tasks: \(backgroundMonitoringEnabled ? "Enabled" : "Disabled")")
                        Text("Check Interval: \(formatInterval(backgroundCheckInterval))")
                        
                        if monitoringService.isDeepTesting {
                            ProgressView("Deep Test Progress", value: monitoringService.deepTestProgress, total: 1.0)
                                .progressViewStyle(.linear)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
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
                
                Button(action: {
                    monitoringService.setupMockData()
                }) {
                    Text("Regenerate Test Data")
                }
            }
            
            Section(header: Text("About")) {
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
                
                Link("Source Code", destination: URL(string: "https://github.com/yourusername/UpTimedb")!)
                
                Link("Report an Issue", destination: URL(string: "https://github.com/yourusername/UpTimedb/issues")!)
            }
            
            Section(header: Text("Home Screen")) {
                Toggle("Show Advanced System Info", isOn: $showAdvancedInfo)
                
                if showAdvancedInfo {
                    Text("Shows detailed system information directly on the home screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("System details will only be shown when viewing individual items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
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
        .onReceive(timer) { _ in
            if isTestingNotification {
                testCountdown -= 1
                if testCountdown == 0 {
                    monitoringService.testNotification()
                    isTestingNotification = false
                    testCountdown = 10
                }
            }
        }
    }
    
    private func startNotificationTest() {
        isTestingNotification = true
        testCountdown = 10
    }
    
    private func formatInterval(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds)) seconds"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60)) minutes"
        } else {
            return "1 hour"
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if !granted {
                print("Notification permission denied")
            }
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func resetAllSettings() {
        apiEndpoint = ""
        simulationEnabled = true
        simulateDowntime = false
        simulateWarnings = false
        dynamicAppIcon = true
        backgroundMonitoringEnabled = false
        backgroundCheckInterval = 300
        simulatedServers = 2
        simulatedServices = 4
        simulatedVMs = 2
        
        monitoringService.setupMockData()
        
        colorSchemeManager.useSystemColorScheme = true
        colorSchemeManager.isDarkMode = false
    }
    
    private func generateDebugReport() -> String {
        var report = "UpTimedb Debug Report\n"
        report += "==================\n\n"
        report += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        report += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n\n"
        
        report += "Settings:\n"
        report += "- Simulation: \(simulationEnabled ? "Enabled" : "Disabled")\n"
        report += "- Simulated Servers: \(simulatedServers)\n"
        report += "- Simulated Services: \(simulatedServices)\n"
        report += "- Background Monitoring: \(backgroundMonitoringEnabled ? "Enabled" : "Disabled")\n"
        report += "- Check Interval: \(formatInterval(backgroundCheckInterval))\n"
        
        report += "\nSystem Status:\n"
        report += "- Overall Status: \(monitoringService.overallStatus.rawValue)\n"
        report += "- Servers Online: \(monitoringService.servers.filter { $0.status == .online }.count)/\(monitoringService.servers.count)\n"
        report += "- Services Online: \(monitoringService.services.filter { $0.status == .online }.count)/\(monitoringService.services.count)\n"
        
        return report
    }
    
    private func exportDebugData() {
        showExportSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 