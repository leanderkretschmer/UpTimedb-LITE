import Foundation
import UserNotifications
import SwiftUI
import BackgroundTasks
import Darwin
import Network

private let HOST_CPU_LOAD_INFO = 3
private let CPU_STATE_USER = 0
private let CPU_STATE_SYSTEM = 1
private let CPU_STATE_IDLE = 2
private let CPU_STATE_NICE = 3
private let CPU_STATE_MAX = 4

class MonitoringService: ObservableObject {
    @Published var servers: [Server] = []
    @Published var services: [Service] = []
    @Published var virtualMachines: [VirtualMachine] = []
    @Published var overallStatus: SystemStatus = .online
    @AppStorage("simulationEnabled") var isSimulated: Bool = true {
        didSet {
            if isSimulated {
                setupMockData()
                startMonitoring()
            } else {
                // Clear all data when simulation is disabled
                servers.removeAll()
                services.removeAll()
                virtualMachines.removeAll()
                timer?.invalidate()
                timer = nil
                warningTimer?.invalidate()
                warningTimer = nil
                deviceTimer?.invalidate()
                deviceTimer = nil
                simulateDowntime = false
                simulateWarnings = false
                deviceMonitor = nil
            }
            updateOverallStatus()
        }
    }
    @Published var simulatedServers: Int = 1
    @Published var simulatedServices: Int = 1
    @Published var simulateDowntime: Bool = false
    @Published var simulateWarnings: Bool = false
    @Published var dynamicAppIcon: Bool = true
    @Published var backgroundCheckInterval: Double = 300 // 5 minutes default
    @Published var isDeepTesting = false
    @Published var deepTestProgress = 0.0
    private var deepTestTimer: Timer?
    @Published var simulatedVMs: Int = 1
    private var timer: Timer?
    private var warningTimer: Timer?
    private var lastWarningCheck = Date()
    private let warningInterval: TimeInterval = 30 // Check every 30 seconds
    private let maxHistoryPoints = 30
    private let backgroundTaskIdentifier = "de.leander-kretschmer.UpTimedb.monitoring"
    @Published var deviceMonitor: DeviceMonitor?
    @Published var monitorLocalDevice: Bool = false
    private var deviceTimer: Timer?
    private var pingHistoryData: [(timestamp: Date, value: Double)] = []
    @Published var overallPingHistory: [(timestamp: Date, value: Double)] = []
    
    init() {
        setupNotifications()
        if isSimulated {
            setupMockData()
            startMonitoring()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAppIconForAppearanceChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        
        if monitorLocalDevice {
            startDeviceMonitoring()
        }
    }
    
    @objc private func updateAppIconForAppearanceChange() {
        updateAppIcon()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func setupMockData() {
        servers = Server.mockServers(count: simulatedServers)
        services = Service.mockServices(servers: servers, count: simulatedServices)
        virtualMachines = VirtualMachine.mockVMs(count: simulatedVMs, servers: servers)
        resetSimulationStatus()
    }
    
    private func resetSimulationStatus() {
        for i in servers.indices {
            servers[i].status = .online
            servers[i].lastPing = Double.random(in: 5...50)
        }
        for i in services.indices {
            services[i].status = .online
            services[i].lastPing = Double.random(in: 5...50)
        }
        updateOverallStatus()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMonitoringData()
        }
    }
    
    private func updateMonitoringData() {
        if isSimulated {
            // Store current ping values with timestamp
            let timestamp = Date()
            let pings = servers.map { $0.lastPing } +
                       services.map { $0.lastPing } +
                       virtualMachines.map { $0.lastPing }
            
            if let devicePing = deviceMonitor?.lastPing {
                pingHistoryData.append((timestamp, devicePing))
            }
            
            for ping in pings {
                pingHistoryData.append((timestamp, ping))
            }
            
            // Keep only last 24 hours of data
            let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
            pingHistoryData = pingHistoryData.filter { $0.timestamp > cutoff }
            
            // Calculate and store overall ping
            let overallPing = calculateOverallPing()
            overallPingHistory.append((timestamp: Date(), value: overallPing))
            
            // Keep only last 24 hours
            let cutoffOverallPing = Date().addingTimeInterval(-24 * 60 * 60)
            overallPingHistory = overallPingHistory.filter { $0.timestamp > cutoffOverallPing }
            
            // Update servers
            for i in servers.indices {
                if servers[i].status == .offline { continue }
                
                let range: ClosedRange<Double> = servers[i].status == .warning ? 
                    100.0...200.0 : // Higher ping for warning state
                    2.0...50.0     // Normal ping range
                
                let newPing = Double.random(in: range)
                servers[i].lastPing = newPing
                
                // Update ping history
                if servers[i].pingHistory.isEmpty {
                    servers[i].pingHistory.append(newPing)
                } else {
                    let lastPing = servers[i].pingHistory.last!
                    let smoothedPing = lastPing * 0.7 + newPing * 0.3
                    servers[i].pingHistory.append(smoothedPing)
                }
                
                if servers[i].pingHistory.count > maxHistoryPoints {
                    servers[i].pingHistory.removeFirst()
                }
                
                // Update system resources
                servers[i].resources.updateMockValues()
            }
            
            // Update services
            for i in services.indices {
                if services[i].status == .offline { continue }
                
                let range: ClosedRange<Double> = services[i].status == .warning ? 
                    100.0...200.0 : // Higher ping for warning state
                    2.0...50.0     // Normal ping range
                
                let newPing = Double.random(in: range)
                services[i].lastPing = newPing
                
                // Update ping history
                if services[i].pingHistory.isEmpty {
                    services[i].pingHistory.append(newPing)
                } else {
                    let lastPing = services[i].pingHistory.last!
                    let smoothedPing = lastPing * 0.7 + newPing * 0.3
                    services[i].pingHistory.append(smoothedPing)
                }
                
                if services[i].pingHistory.count > maxHistoryPoints {
                    services[i].pingHistory.removeFirst()
                }
            }
            
            // Update virtual machines
            for i in virtualMachines.indices {
                if virtualMachines[i].status == .offline { continue }
                
                let range: ClosedRange<Double> = virtualMachines[i].status == .warning ? 
                    100.0...200.0 : // Higher ping for warning state
                    2.0...50.0     // Normal ping range
                
                let newPing = Double.random(in: range)
                virtualMachines[i].lastPing = newPing
                
                // Update ping history
                if virtualMachines[i].pingHistory.isEmpty {
                    virtualMachines[i].pingHistory.append(newPing)
                } else {
                    let lastPing = virtualMachines[i].pingHistory.last!
                    let smoothedPing = lastPing * 0.7 + newPing * 0.3
                    virtualMachines[i].pingHistory.append(smoothedPing)
                }
                
                if virtualMachines[i].pingHistory.count > maxHistoryPoints {
                    virtualMachines[i].pingHistory.removeFirst()
                }
                
                // Update system resources
                virtualMachines[i].resources.updateMockValues()
            }
            
            updateOverallStatus()
        }
    }
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task as! BGAppRefreshTask)
        }
    }
    
    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundCheckInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        updateMonitoringData()
        scheduleBackgroundTask()
        task.setTaskCompleted(success: true)
    }
    
    func testNotification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.sendNotification(
                title: "Test Notification",
                message: "Background notifications are working! Test completed successfully."
            )
        }
    }
    
    private func sendNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    private func updateOverallStatus() {
        // Calculate weighted ping averages
        let serverPings = calculateWeightedPings(servers.map { $0.lastPing })
        let servicePings = calculateWeightedPings(services.map { $0.lastPing })
        let vmPings = calculateWeightedPings(virtualMachines.map { $0.lastPing })
        let devicePing = deviceMonitor.map { calculateWeightedPings([$0.lastPing]) } ?? 0
        
        // Get highest weighted ping
        let highestPing = max(serverPings, servicePings, vmPings, devicePing)
        
        // Check for offline status first
        let hasOfflineStatus = servers.contains(where: { $0.status == .offline }) || 
                              services.contains(where: { $0.status == .offline }) ||
                              virtualMachines.contains(where: { $0.status == .offline }) ||
                              deviceMonitor?.status == .offline
        
        // Check for warning status
        let hasWarningStatus = servers.contains(where: { $0.status == .warning }) || 
                              services.contains(where: { $0.status == .warning }) ||
                              virtualMachines.contains(where: { $0.status == .warning }) ||
                              deviceMonitor?.status == .warning
        
        // Determine overall status based on weighted pings and existing statuses
        if hasOfflineStatus {
            overallStatus = .offline
        } else if hasWarningStatus || highestPing > 100 {
            overallStatus = .warning
        } else if !isSimulated && deviceMonitor == nil {
            overallStatus = .offline
        } else {
            overallStatus = .online
        }
        
        updateAppIcon()
    }
    
    private func calculateWeightedPings(_ pings: [Double]) -> Double {
        guard !pings.isEmpty else { return 0 }
        
        // Sort pings in ascending order
        let sortedPings = pings.sorted()
        
        // Calculate weights based on ping values
        // Higher pings get exponentially higher weights
        let weights = sortedPings.map { ping -> Double in
            if ping > 200 { return 4.0 }      // Extremely high ping
            else if ping > 150 { return 3.0 }  // Very high ping
            else if ping > 100 { return 2.0 }  // High ping
            else if ping > 50 { return 1.5 }   // Moderate ping
            else { return 1.0 }                // Normal ping
        }
        
        // Calculate weighted average
        let totalWeight = weights.reduce(0, +)
        let weightedSum = zip(sortedPings, weights).map { $0.0 * $0.1 }.reduce(0, +)
        
        return weightedSum / totalWeight
    }
    
    func updateServerNotificationSetting(serverId: UUID, notifyOnOffline: Bool? = nil, notifyOnStorageWarning: Bool? = nil, storageThreshold: Double? = nil) {
        if let serverIndex = servers.firstIndex(where: { $0.id == serverId }) {
            if let notifyOnOffline = notifyOnOffline {
                servers[serverIndex].notificationSettings.notifyOnOffline = notifyOnOffline
            }
            if let notifyOnStorageWarning = notifyOnStorageWarning {
                servers[serverIndex].notificationSettings.notifyOnStorageWarning = notifyOnStorageWarning
            }
            if let storageThreshold = storageThreshold {
                servers[serverIndex].notificationSettings.storageWarningThreshold = storageThreshold
            }
        }
    }
    
    func updateSimulationSettings() {
        if !simulateDowntime && !simulateWarnings {
            resetAllStatuses()
            warningTimer?.invalidate()
            warningTimer = nil
            return
        }
        
        // Handle warnings simulation
        if simulateWarnings {
            // Take random items to warning state
            if let index = servers.indices.randomElement() {
                servers[index].status = .warning
                servers[index].lastPing = Double.random(in: 100...200)
            }
            if let index = services.indices.randomElement() {
                services[index].status = .warning
                services[index].lastPing = Double.random(in: 100...200)
            }
            if let index = virtualMachines.indices.randomElement() {
                virtualMachines[index].status = .warning
                virtualMachines[index].lastPing = Double.random(in: 100...200)
            }
        }
        
        // Handle downtime simulation
        if simulateDowntime {
            // Take a random server and its services offline
            if let serverIndex = servers.indices.randomElement() {
                // Take the server offline
                servers[serverIndex].status = .offline
                servers[serverIndex].lastPing = 0
                
                // Take all services on this server offline
                let serverId = servers[serverIndex].id
                for i in services.indices where services[i].serverId == serverId {
                    services[i].status = .offline
                    services[i].lastPing = 0
                }
                
                // Take all VMs on this server offline
                for i in virtualMachines.indices where virtualMachines[i].parentServerId == serverId {
                    virtualMachines[i].status = .offline
                    virtualMachines[i].lastPing = 0
                }
            }
        }
        
        // Update overall status and app icon
        updateOverallStatus()
    }
    
    private func simulateRandomWarning() {
        // Choose between server and service warning
        if Bool.random() {
            // Server warning
            if let randomServerIndex = servers.indices.randomElement() {
                // Only set warning if server isn't offline
                if servers[randomServerIndex].status != .offline {
                    servers[randomServerIndex].status = .warning
                    servers[randomServerIndex].lastPing = Double.random(in: 100...200)
                    
                    // Update ping history
                    if servers[randomServerIndex].pingHistory.count > maxHistoryPoints {
                        servers[randomServerIndex].pingHistory.removeFirst()
                    }
                    servers[randomServerIndex].pingHistory.append(servers[randomServerIndex].lastPing)
                }
            }
        } else {
            // Service warning
            if let randomServiceIndex = services.indices.randomElement() {
                // Only set warning if service isn't offline
                if services[randomServiceIndex].status != .offline {
                    services[randomServiceIndex].status = .warning
                    services[randomServiceIndex].lastPing = Double.random(in: 100...200)
                    
                    // Update ping history
                    if services[randomServiceIndex].pingHistory.count > maxHistoryPoints {
                        services[randomServiceIndex].pingHistory.removeFirst()
                    }
                    services[randomServiceIndex].pingHistory.append(services[randomServiceIndex].lastPing)
                }
            }
        }
        
        // Update overall status and app icon
        updateOverallStatus()
    }
    
    func updateAppIcon() {
        guard dynamicAppIcon else {
            setAppIcon(nil) // Default icon
            return
        }
        
        switch overallStatus {
        case .warning:
            setAppIcon("AppIcon-Warning")
        case .offline:
            setAppIcon("AppIcon-Error")
        case .online:
            setAppIcon(nil) // Use default icon
        }
    }
    
    private func setAppIcon(_ iconName: String?) {
        if UIApplication.shared.supportsAlternateIcons {
            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    print("Error setting app icon: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func startDeepTest() {
        isDeepTesting = true
        deepTestProgress = 0.0
        
        // Reset and create test data
        servers = Server.mockServers(count: 5)
        services = Service.mockServices(servers: servers, count: 8)
        virtualMachines = VirtualMachine.mockVMs(count: 4, servers: servers)
        
        // Start deep test cycle
        deepTestTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.runDeepTestCycle()
        }
        
        // Initial test cycle
        runDeepTestCycle()
    }
    
    func stopDeepTest() {
        isDeepTesting = false
        deepTestTimer?.invalidate()
        deepTestTimer = nil
        deepTestProgress = 0.0
        setupMockData() // Reset to normal mock data
    }
    
    private func runDeepTestCycle() {
        // Simulate different scenarios
        let scenario = Int.random(in: 0...4)
        
        switch scenario {
        case 0: // All normal
            resetAllStatuses()
        case 1: // Warning state
            simulateRandomWarning()
        case 2: // Error state
            simulateRandomError()
        case 3: // Mixed state
            simulateMixedState()
        case 4: // Recovery state
            simulateRecovery()
        default:
            break
        }
        
        // Update progress
        deepTestProgress += 0.1
        if deepTestProgress >= 1.0 {
            deepTestProgress = 0.0
        }
        
        // Test notifications
        testNotification()
        
        updateOverallStatus()
    }
    
    private func simulateRandomError() {
        // Take random items offline
        if let index = servers.indices.randomElement() {
            servers[index].status = .offline
            servers[index].lastPing = 0
        }
        if let index = services.indices.randomElement() {
            services[index].status = .offline
            services[index].lastPing = 0
        }
        if let index = virtualMachines.indices.randomElement() {
            virtualMachines[index].status = .offline
            virtualMachines[index].lastPing = 0
        }
    }
    
    private func simulateMixedState() {
        // Create a mix of warnings and errors
        for index in servers.indices {
            servers[index].status = SystemStatus.allCases.randomElement() ?? .online
        }
        for index in services.indices {
            services[index].status = SystemStatus.allCases.randomElement() ?? .online
        }
        for index in virtualMachines.indices {
            virtualMachines[index].status = SystemStatus.allCases.randomElement() ?? .online
        }
    }
    
    private func simulateRecovery() {
        // Gradually recover systems from error/warning states
        for index in servers.indices {
            if servers[index].status == .offline {
                servers[index].status = .warning
            } else if servers[index].status == .warning {
                servers[index].status = .online
            }
        }
        
        for index in services.indices {
            if services[index].status == .offline {
                services[index].status = .warning
            } else if services[index].status == .warning {
                services[index].status = .online
            }
        }
        
        for index in virtualMachines.indices {
            if virtualMachines[index].status == .offline {
                virtualMachines[index].status = .warning
            } else if virtualMachines[index].status == .warning {
                virtualMachines[index].status = .online
            }
        }
    }
    
    private func resetAllStatuses() {
        // Reset servers
        for i in servers.indices {
            servers[i].status = .online
            servers[i].lastPing = Double.random(in: 5...50)
            if servers[i].pingHistory.isEmpty {
                servers[i].pingHistory = Array(repeating: Double.random(in: 5...50), count: maxHistoryPoints)
            }
        }
        
        // Reset services
        for i in services.indices {
            services[i].status = .online
            services[i].lastPing = Double.random(in: 5...50)
            if services[i].pingHistory.isEmpty {
                services[i].pingHistory = Array(repeating: Double.random(in: 5...50), count: maxHistoryPoints)
            }
        }
        
        // Reset virtual machines
        for i in virtualMachines.indices {
            virtualMachines[i].status = .online
            virtualMachines[i].lastPing = Double.random(in: 5...50)
            if virtualMachines[i].pingHistory.isEmpty {
                virtualMachines[i].pingHistory = Array(repeating: Double.random(in: 5...50), count: maxHistoryPoints)
            }
            virtualMachines[i].resources.updateMockValues()
        }
        
        // Update overall status
        updateOverallStatus()
    }
    
    func startDeviceMonitoring() {
        deviceMonitor = DeviceMonitor.createLocal()
        deviceTimer?.invalidate()
        deviceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateDeviceStatus()
        }
        // Initial update
        updateDeviceStatus()
    }
    
    func stopDeviceMonitoring() {
        deviceTimer?.invalidate()
        deviceTimer = nil
        deviceMonitor = nil
    }
    
    private func updateDeviceStatus() {
        guard var device = deviceMonitor else { return }
        
        // Set static zero values for resources
        device.resources.cpuUsage = 0
        device.resources.memoryUsage = 0
        device.resources.drives = [
            DriveInfo(name: "System", totalSpace: 512, usedSpace: 0),
            DriveInfo(name: "Data", totalSpace: 1024, usedSpace: 0)
        ]
        
        // Real ping test to 1.1.1.1
        pingCloudflare { pingTime in
            DispatchQueue.main.async {
                device.lastPing = pingTime
                
                // Initialize ping history if empty
                if device.pingHistory.isEmpty {
                    device.pingHistory = Array(repeating: 0.0, count: 20)
                }
                
                // Add new ping and remove oldest if needed
                device.pingHistory.append(pingTime)
                if device.pingHistory.count > 20 {  // Keep only last 20 values
                    device.pingHistory.removeFirst()
                }
                
                // Update status based on real ping
                if pingTime == 0 {
                    device.status = .offline
                } else if pingTime > 100 {
                    device.status = .warning
                } else {
                    device.status = .online
                }
                
                self.deviceMonitor = device
                self.updateOverallStatus()
            }
        }
    }
    
    private func pingCloudflare(completion: @escaping (Double) -> Void) {
        let startTime = Date()
        let url = URL(string: "https://1.1.1.1")!
        let task = URLSession.shared.dataTask(with: url) { _, _, error in
            let pingTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
            completion(error == nil ? pingTime : 0)
        }
        task.resume()
    }
    
    func getPingHistory(forLast seconds: Int) -> [(timestamp: Date, value: Double)] {
        let cutoff = Date().addingTimeInterval(-Double(seconds))
        return pingHistoryData.filter { $0.timestamp > cutoff }
    }
    
    private func calculateOverallPing() -> Double {
        var pings: [Double] = []
        
        // Collect all current pings
        pings.append(contentsOf: servers.map { $0.lastPing })
        pings.append(contentsOf: services.map { $0.lastPing })
        pings.append(contentsOf: virtualMachines.map { $0.lastPing })
        if let devicePing = deviceMonitor?.lastPing {
            pings.append(devicePing)
        }
        
        // Calculate weighted average
        let weights = pings.map { ping -> Double in
            if ping > 200 { return 4.0 }      // Extremely high ping
            else if ping > 150 { return 3.0 }  // Very high ping
            else if ping > 100 { return 2.0 }  // High ping
            else if ping > 50 { return 1.5 }   // Moderate ping
            else { return 1.0 }                // Normal ping
        }
        
        let totalWeight = weights.reduce(0, +)
        let weightedSum = zip(pings, weights).map { $0 * $1 }.reduce(0, +)
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0
    }
} 