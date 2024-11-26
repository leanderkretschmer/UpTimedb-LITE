//
//  ContentView.swift
//  UpTimedb
//
//  Created by leander kretschmer on 25.11.24.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var monitoringService = MonitoringService()
    @State private var expandedSections: Set<String> = ["device", "servers", "services", "vms"]
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    
    private var hasActiveMonitoring: Bool {
        monitoringService.deviceMonitor != nil || 
        monitoringService.isSimulated ||
        !apiEndpoint.isEmpty
    }
    
    private var totalDevices: Int {
        monitoringService.servers.count + 
        monitoringService.services.count + 
        monitoringService.virtualMachines.count + 
        (monitoringService.deviceMonitor != nil ? 1 : 0)
    }
    
    private var onlineDevices: Int {
        let onlineServers = monitoringService.servers.filter { $0.status == .online }.count
        let onlineServices = monitoringService.services.filter { $0.status == .online }.count
        let onlineVMs = monitoringService.virtualMachines.filter { $0.status == .online }.count
        let deviceOnline = monitoringService.deviceMonitor?.status == .online ? 1 : 0
        return onlineServers + onlineServices + onlineVMs + deviceOnline
    }
    
    private var orderedSections: [(String, Int, [any StatusProvider])] {
        let sections = [
            ("Servers", monitoringService.servers.filter { $0.status == .online }.count, monitoringService.servers as [any StatusProvider]),
            ("Virtual Machines", monitoringService.virtualMachines.filter { $0.status == .online }.count, monitoringService.virtualMachines as [any StatusProvider]),
            ("Services", monitoringService.services.filter { $0.status == .online }.count, monitoringService.services as [any StatusProvider])
        ]
        
        // Sort sections: non-empty first, then empty ones
        return sections.sorted { first, second in
            // If both are empty or both are non-empty, maintain original order
            if first.2.isEmpty == second.2.isEmpty {
                return sections.firstIndex(where: { $0.0 == first.0 })! < 
                       sections.firstIndex(where: { $0.0 == second.0 })!
            }
            // Non-empty sections go first
            return !first.2.isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 20) {
                    // Overall Status Widget
                    if hasActiveMonitoring {
                        OverallStatusWidget(
                            monitoringService: monitoringService,
                            totalDevices: totalDevices,
                            onlineDevices: onlineDevices,
                            servers: monitoringService.servers.filter { $0.status == .online }.count,
                            services: monitoringService.services.filter { $0.status == .online }.count,
                            vms: monitoringService.virtualMachines.filter { $0.status == .online }.count
                        )
                        .padding(.horizontal)
                    } else {
                        OverallStatusWidget(monitoringService: monitoringService)
                            .padding(.horizontal)
                            .opacity(0.5)
                    }
                    
                    // Local Device Section - Always first if enabled
                    if let device = monitoringService.deviceMonitor {
                        CollapsibleSection(
                            title: "Local Device",
                            subtitle: "Status: \(device.status.rawValue) • Ping: \(Int(device.lastPing))ms",
                            isExpanded: true  // Always expanded when present
                        ) {
                            NavigationLink(destination: DeviceDetailView(device: device)) {
                                DeviceWidget(device: device)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Ordered Sections
                    ForEach(orderedSections, id: \.0) { title, onlineCount, items in
                        CollapsibleSection(
                            title: title,
                            subtitle: items.isEmpty ? "0 Online" : statusSummary(items),
                            isExpanded: title == "Virtual Machines" ? true : (!items.isEmpty && expandedSections.contains(title.lowercased()))
                        ) {
                            if !items.isEmpty {
                                Group {
                                    switch title {
                                    case "Servers":
                                        ServersListWidget(
                                            servers: monitoringService.servers,
                                            services: monitoringService.services,
                                            monitoringService: monitoringService
                                        )
                                    case "Services":
                                        ServicesWidget(
                                            services: monitoringService.services,
                                            servers: monitoringService.servers
                                        )
                                    case "Virtual Machines":
                                        VMsWidget(
                                            vms: monitoringService.virtualMachines,
                                            servers: monitoringService.servers,
                                            monitoringService: monitoringService
                                        )
                                    default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            if !items.isEmpty {
                                toggleSection(title.lowercased())
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("System Status")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView(monitoringService: monitoringService)) {
                        Image(systemName: "gear")
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func statusSummary(_ items: [any StatusProvider]) -> String {
        let online = items.filter { $0.status == SystemStatus.online }.count
        let errors = items.filter { $0.status == SystemStatus.offline }.count
        let warnings = items.filter { $0.status == SystemStatus.warning }.count
        return "\(online)/\(items.count) Online • \(errors) Errors • \(warnings) Warnings"
    }
    
    private func toggleSection(_ id: String) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }
}

struct CollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String
    let isExpanded: Bool
    @ViewBuilder let content: () -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isExpanded {
                VStack(spacing: 16) {
                    content()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    ContentView()
}
