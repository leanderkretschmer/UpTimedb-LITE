import SwiftUI

struct SettingsView: View {
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    @AppStorage("simulationEnabled") private var simulationEnabled: Bool = true
    @AppStorage("simulateDowntime") private var simulateDowntime: Bool = false
    @AppStorage("simulateWarnings") private var simulateWarnings: Bool = false
    @AppStorage("dynamicAppIcon") private var dynamicAppIcon: Bool = true
    @AppStorage("backgroundMonitoringEnabled") private var backgroundMonitoringEnabled: Bool = false
    @AppStorage("backgroundCheckInterval") private var backgroundCheckInterval: Double = 300
    @AppStorage("simulatedServers") private var simulatedServers: Int = 1
    @AppStorage("simulatedServices") private var simulatedServices: Int = 1
    @AppStorage("simulatedVMs") private var simulatedVMs: Int = 1
    @AppStorage("showAdvancedInfo") private var showAdvancedInfo: Bool = false
    @ObservedObject var monitoringService: MonitoringService
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
            // 1. API Configuration
            Section(header: Text("API Configuration")) {
                TextField("API Endpoint", text: $apiEndpoint)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("API Key", text: .constant(""))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // 2. Monitoring
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
                }
                
                Toggle("Show Advanced System Info", isOn: $showAdvancedInfo)
            }
            
            // 3. Device Monitoring
            Section(header: Text("Device Monitoring")) {
                Toggle("Monitor This Device", isOn: $monitoringService.monitorLocalDevice)
                    .onChange(of: monitoringService.monitorLocalDevice) { newValue in
                        if newValue {
                            monitoringService.startDeviceMonitoring()
                        } else {
                            monitoringService.stopDeviceMonitoring()
                        }
                    }
                
                if monitoringService.monitorLocalDevice {
                    Text("Monitors network latency to 1.1.1.1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 4. Simulation
            Section(header: Text("Simulation")) {
                Toggle("Enable Simulation", isOn: $simulationEnabled)
                    .onChange(of: simulationEnabled) { newValue in
                        monitoringService.isSimulated = newValue
                    }
                
                if simulationEnabled {
                    VStack(alignment: .leading) {
                        Text("Servers: \(simulatedServers)")
                        Slider(value: .init(
                            get: { Double(simulatedServers) },
                            set: { simulatedServers = Int($0) }
                        ), in: 1...8, step: 1)
                        .onAppear {
                            simulatedServers = max(1, monitoringService.servers.count)
                        }
                        .onDisappear {
                            monitoringService.simulatedServers = max(1, simulatedServers)
                            monitoringService.setupMockData()
                        }
                        
                        Text("Virtual Machines: \(simulatedVMs)")
                        Slider(value: .init(
                            get: { Double(simulatedVMs) },
                            set: { simulatedVMs = Int($0) }
                        ), in: 0...6, step: 1)
                        .onAppear {
                            simulatedVMs = monitoringService.virtualMachines.count
                        }
                        .onDisappear {
                            monitoringService.simulatedVMs = simulatedVMs
                            monitoringService.setupMockData()
                        }
                        
                        Text("Services: \(simulatedServices)")
                        Slider(value: .init(
                            get: { Double(simulatedServices) },
                            set: { simulatedServices = Int($0) }
                        ), in: 0...12, step: 1)
                        .onAppear {
                            simulatedServices = monitoringService.services.count
                        }
                        .onDisappear {
                            monitoringService.simulatedServices = simulatedServices
                            monitoringService.setupMockData()
                        }
                    }
                    
                    Toggle("Simulate Downtime", isOn: $simulateDowntime)
                    Toggle("Simulate Warnings", isOn: $simulateWarnings)
                }
            }
            
            // 5. Appearance
            Section(header: Text("Appearance")) {
                Toggle("Dynamic App Icon", isOn: $dynamicAppIcon)
                Toggle("Use System Theme", isOn: $colorSchemeManager.useSystemColorScheme)
                
                if !colorSchemeManager.useSystemColorScheme {
                    Toggle("Dark Mode", isOn: $colorSchemeManager.isDarkMode)
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                NavigationLink(destination: DevToolsView(monitoringService: monitoringService)) {
                    Label("Developer Tools", systemImage: "hammer")
                }
            }
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
} 