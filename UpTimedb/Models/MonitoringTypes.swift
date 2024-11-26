import Foundation
import SwiftUI

protocol StatusProvider {
    var status: SystemStatus { get }
}

// Make our types conform to StatusProvider
extension Server: StatusProvider {}
extension Service: StatusProvider {}
extension VirtualMachine: StatusProvider {}
extension DeviceMonitor: StatusProvider {}

enum SystemStatus: String, CaseIterable {
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
    var memoryUsage: Double // Percentage (0-100)
    var drives: [DriveInfo]
    
    static func mockResources() -> SystemResources {
        SystemResources(
            cpuUsage: Double.random(in: 20...80),
            memoryUsage: Double.random(in: 30...90),
            drives: [
                DriveInfo(name: "System", totalSpace: 512, usedSpace: Double.random(in: 200...400)),
                DriveInfo(name: "Data", totalSpace: 1024, usedSpace: Double.random(in: 400...800))
            ]
        )
    }
    
    mutating func updateMockValues() {
        // Simulate realistic changes in resource usage
        cpuUsage = max(0, min(100, cpuUsage + Double.random(in: -10...10)))
        memoryUsage = max(0, min(100, memoryUsage + Double.random(in: -5...5)))
        
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
    var ipAddress: String
    var location: String  // e.g., "Data Center 1"
    var type: String      // e.g., "Physical", "Cloud"
    
    static func mockServers(count: Int) -> [Server] {
        return (0..<count).map { i in
            Server(
                id: UUID(),
                name: SimulationConfig.serverNames[i % SimulationConfig.serverNames.count],
                status: .online,
                pingHistory: Array(repeating: Double.random(in: 5...50), count: 30),
                lastPing: Double.random(in: 5...50),
                resources: .mockResources(),
                notificationSettings: ServerNotificationSettings(),
                ipAddress: "192.168.0.\(10 + i)",
                location: "Data Center \(i % 3 + 1)",
                type: i % 2 == 0 ? "Physical" : "Cloud"
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
                name: SimulationConfig.serviceNames[i % SimulationConfig.serviceNames.count],
                serverId: servers[serverIndex].id,
                status: .online,
                pingHistory: Array(repeating: Double.random(in: 5...50), count: 30),
                lastPing: Double.random(in: 5...50)
            )
        }
    }
}

struct VirtualMachine: Identifiable {
    let id: UUID
    var name: String
    var status: SystemStatus
    var resources: SystemResources
    var lastPing: Double
    var pingHistory: [Double]
    var ipAddress: String
    var parentServerId: UUID
    
    static func mockVMs(count: Int, servers: [Server]) -> [VirtualMachine] {
        return (0..<count).map { i in
            let parentServer = servers[i % servers.count]
            return VirtualMachine(
                id: UUID(),
                name: "VM-\(SimulationConfig.serverNames[i % SimulationConfig.serverNames.count])",
                status: .online,
                resources: .mockResources(),
                lastPing: Double.random(in: 5...50),
                pingHistory: Array(repeating: Double.random(in: 5...50), count: 30),
                ipAddress: "192.168.1.\(100 + i)",
                parentServerId: parentServer.id
            )
        }
    }
}

struct SimulationConfig {
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

struct DeviceMonitor: Identifiable {
    let id = UUID()
    var name: String
    var status: SystemStatus
    var resources: SystemResources
    var lastPing: Double
    var pingHistory: [Double]
    var ipAddress: String
    
    static func createLocal() -> DeviceMonitor {
        DeviceMonitor(
            name: UIDevice.current.name,
            status: .online,
            resources: .mockResources(),
            lastPing: 0,
            pingHistory: [],
            ipAddress: DeviceMonitor.getLocalIPAddress() ?? "Unknown"
        )
    }
    
    static func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: (interface?.ifa_name)!)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface?.ifa_addr,
                              socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              0,
                              NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
} 