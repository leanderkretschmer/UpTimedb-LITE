import Foundation
import UserNotifications
import SwiftUI
import BackgroundTasks

class MonitoringService: ObservableObject {
    @Published var servers: [Server] = []
    @Published var services: [Service] = []
    @Published var overallStatus: SystemStatus = .online
    @Published var isSimulated: Bool = true
    @Published var simulatedServers: Int = 2
    @Published var simulatedServices: Int = 3
    @Published var simulateDowntime: Bool = false
    @Published var simulateWarnings: Bool = false
    @Published var dynamicAppIcon: Bool = true
    @Published var backgroundCheckInterval: Double = 300 // 5 minutes default
    
    private var timer: Timer?
    private var warningTimer: Timer?
    private var lastWarningCheck = Date()
    private let warningInterval: TimeInterval = 30 // Check every 30 seconds
    private let maxHistoryPoints = 30
    private let backgroundTaskIdentifier = "de.leander-kretschmer.UpTimedb.monitoring"
    
    init() {
        setupNotifications()
        if isSimulated {
            setupMockData()
            startMonitoring()
        }
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
            updateSimulatedData()
        } else {
            // Here we would make API calls to get real data
        }
        
        updateOverallStatus()
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
    
    private func updateSimulatedData() {
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
        
        updateOverallStatus()
    }
    
    private func updateOverallStatus() {
        if servers.contains(where: { $0.status == .offline }) || 
           services.contains(where: { $0.status == .offline }) {
            overallStatus = .offline
        } else if servers.contains(where: { $0.status == .warning }) || 
                  services.contains(where: { $0.status == .warning }) {
            overallStatus = .warning
        } else {
            overallStatus = .online
        }
        
        updateAppIcon()
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
            // Reset all statuses to online
            resetSimulationStatus()
            warningTimer?.invalidate()
            warningTimer = nil
            return
        }
        
        if simulateWarnings {
            // Start warning simulation timer if not already running
            if warningTimer == nil {
                warningTimer = Timer.scheduledTimer(withTimeInterval: warningInterval, repeats: true) { [weak self] _ in
                    self?.simulateRandomWarning()
                }
                // Trigger initial warning
                simulateRandomWarning()
            }
        } else {
            warningTimer?.invalidate()
            warningTimer = nil
        }
        
        if simulateDowntime {
            // Simulate one server and its services going offline
            if let randomServerIndex = servers.indices.randomElement() {
                servers[randomServerIndex].status = .offline
                servers[randomServerIndex].lastPing = 0
                
                // Take down all services on this server
                for i in services.indices where services[i].serverId == servers[randomServerIndex].id {
                    services[i].status = .offline
                    services[i].lastPing = 0
                }
            }
        }
        
        updateOverallStatus()
    }
    
    private func simulateRandomWarning() {
        // Reset any previous warnings
        for i in servers.indices where servers[i].status == .warning {
            servers[i].status = .online
        }
        for i in services.indices where services[i].status == .warning {
            services[i].status = .online
        }
        
        // Randomly choose between server and service warning
        if Bool.random() {
            if let randomServerIndex = servers.indices.randomElement() {
                servers[randomServerIndex].status = .warning
            }
        } else {
            if let randomServiceIndex = services.indices.randomElement() {
                services[randomServiceIndex].status = .warning
            }
        }
        
        updateOverallStatus()
    }
    
    func updateAppIcon() {
        guard dynamicAppIcon else {
            setAppIcon(nil) // Default icon
            return
        }
        
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        let iconPrefix = isDarkMode ? "icon_dark" : "icon_any"
        
        switch overallStatus {
        case .offline:
            setAppIcon("\(iconPrefix)_error")
        case .warning:
            setAppIcon("\(iconPrefix)_warning")
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
} 