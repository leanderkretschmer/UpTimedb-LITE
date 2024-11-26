import SwiftUI

struct SettingsView: View {
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    @AppStorage("simulationEnabled") private var simulationEnabled: Bool = true
    @AppStorage("simulateDowntime") private var simulateDowntime: Bool = false
    @AppStorage("simulateWarnings") private var simulateWarnings: Bool = false
    @AppStorage("dynamicAppIcon") private var dynamicAppIcon: Bool = true
    @AppStorage("backgroundMonitoringEnabled") private var backgroundMonitoringEnabled: Bool = false
    @AppStorage("backgroundCheckInterval") private var backgroundCheckInterval: Double = 300 // 5 minutes default
    @AppStorage("simulatedServers") private var simulatedServers: Int = 2
    @AppStorage("simulatedServices") private var simulatedServices: Int = 4
    @StateObject private var monitoringService = MonitoringService()
    @State private var isTestingNotification = false
    @State private var testCountdown = 10
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
            
            Section(header: Text("Testing & Development")) {
                Toggle("Enable Simulation", isOn: $simulationEnabled)
                
                if simulationEnabled {
                    Stepper("Servers: \(simulatedServers)", value: $simulatedServers, in: 1...8)
                        .onChange(of: simulatedServers) { oldValue, newValue in
                            monitoringService.setupMockData()
                        }
                    
                    Stepper("Services: \(simulatedServices)", value: $simulatedServices, in: 1...12)
                        .onChange(of: simulatedServices) { oldValue, newValue in
                            monitoringService.setupMockData()
                        }
                    
                    Toggle("Simulate Downtime", isOn: $simulateDowntime)
                        .onChange(of: simulateDowntime) { oldValue, newValue in
                            monitoringService.updateSimulationSettings()
                        }
                    
                    Toggle("Simulate Warnings", isOn: $simulateWarnings)
                        .onChange(of: simulateWarnings) { oldValue, newValue in
                            monitoringService.updateSimulationSettings()
                        }
                    
                    Text("Using simulated data for testing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        startNotificationTest()
                    }) {
                        if isTestingNotification {
                            HStack {
                                Text("Testing in \(testCountdown)s...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Text("Test Notification")
                        }
                    }
                    .disabled(isTestingNotification)
                    .foregroundColor(isTestingNotification ? .secondary : .blue)
                    
                    Text("Close the app within 10 seconds to test background notifications")
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
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.2.5")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
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
} 