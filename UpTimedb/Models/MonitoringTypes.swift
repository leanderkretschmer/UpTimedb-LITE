import Foundation
import SwiftUI

enum SystemStatus: String {
    case online = "Online"
    case offline = "Offline"
    case warning = "Warning"
    
    var color: Color {
        switch self {
        case .online: return .green
        case .offline: return .red
        case .warning: return .orange
        }
    }
}

struct SystemResources {
    var cpuUsage: Double // Percentage (0-100)
    var ramUsage: Double // Percentage (0-100)
    var gpuUsage: Double // Percentage (0-100)
    var networkUsage: Double // Percentage (0-100)
    var drives: [DriveInfo]
    
    static func mockResources() -> SystemResources {
        SystemResources(
            cpuUsage: Double.random(in: 20...80),
            ramUsage: Double.random(in: 30...90),
            gpuUsage: Double.random(in: 10...95),
            networkUsage: Double.random(in: 5...60),
            drives: [
                DriveInfo(name: "System (C:)", totalSpace: 512, usedSpace: 384),
                DriveInfo(name: "Data (D:)", totalSpace: 1024, usedSpace: 768),
                DriveInfo(name: "Backup (E:)", totalSpace: 2048, usedSpace: 1024)
            ]
        )
    }
    
    mutating func updateMockValues() {
        // Simulate realistic changes in resource usage
        cpuUsage = max(0, min(100, cpuUsage + Double.random(in: -10...10)))
        ramUsage = max(0, min(100, ramUsage + Double.random(in: -5...5)))
        gpuUsage = max(0, min(100, gpuUsage + Double.random(in: -8...8)))
        networkUsage = max(0, min(100, networkUsage + Double.random(in: -15...15)))
        
        // Simulate small changes in drive usage
        for i in drives.indices {
            drives[i].usedSpace = max(0, min(drives[i].totalSpace,
                drives[i].usedSpace + Double.random(in: -10...10)))
        }
    }
}

struct DriveInfo: Identifiable {
    let id = UUID()
    var name: String
    var totalSpace: Double // GB
    var usedSpace: Double // GB
    
    var freeSpace: Double { totalSpace - usedSpace }
    var usagePercentage: Double { (usedSpace / totalSpace) * 100 }
}

struct ServerNotificationSettings {
    var notifyOnOffline: Bool = true
    var notifyOnStorageWarning: Bool = false
    var storageWarningThreshold: Double = 75.0 // Percentage
}

struct Server: Identifiable {
    let id: UUID
    var name: String
    var status: SystemStatus
    var pingHistory: [Double]
    var lastPing: Double
    var resources: SystemResources
    var notificationSettings: ServerNotificationSettings
    
    static func mockServers(count: Int) -> [Server] {
        return (0..<count).map { i in
            Server(
                id: UUID(),
                name: "Server \(i + 1)",
                status: .online,
                pingHistory: [],
                lastPing: Double.random(in: 5...50),
                resources: .mockResources(),
                notificationSettings: ServerNotificationSettings()
            )
        }
    }
}

struct Service: Identifiable {
    let id: UUID
    var name: String
    var serverId: UUID
    var status: SystemStatus
    var pingHistory: [Double]
    var lastPing: Double
    
    static func mockServices(servers: [Server], count: Int) -> [Service] {
        return (0..<count).map { i in
            let serverIndex = i % servers.count
            return Service(
                id: UUID(),
                name: "Service \(i + 1)",
                serverId: servers[serverIndex].id,
                status: .online,
                pingHistory: [],
                lastPing: Double.random(in: 5...50)
            )
        }
    }
}

struct SimulationConfig {
    var numberOfServers: Int = 2
    var numberOfServices: Int = 4
    
    static let serverNames = [
        "Web Server",
        "Database Server",
        "API Server",
        "Cache Server",
        "Auth Server",
        "Storage Server",
        "Backup Server",
        "Load Balancer"
    ]
    
    static let serviceNames = [
        "Web Frontend",
        "Database",
        "API Gateway",
        "Cache Service",
        "Authentication",
        "Storage Service",
        "Backup Service",
        "Load Balancer",
        "Search Service",
        "Message Queue",
        "Email Service",
        "Monitoring Service"
    ]
} 