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
    @State private var expandedSections: Set<String> = ["servers", "services", "vms", "device"]
    @AppStorage("apiEndpoint") private var apiEndpoint: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 20) {
                    // Overall Status Widget - Always show
                    OverallStatusWidget(monitoringService: monitoringService)
                        .padding(.horizontal)
                        .opacity(apiEndpoint.isEmpty && !monitoringService.isSimulated ? 0.5 : 1.0)
                    
                    // Local Device Section - Always show if monitoring is enabled
                    if let device = monitoringService.deviceMonitor {
                        CollapsibleSection(
                            title: "Local Device",
                            subtitle: "Status: \(device.status.rawValue) • Ping: \(Int(device.lastPing))ms",
                            isExpanded: expandedSections.contains("device")
                        ) {
                            NavigationLink(destination: DeviceDetailView(device: device)) {
                                DeviceWidget(device: device)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            toggleSection("device")
                        }
                    }
                    
                    // Servers Section
                    CollapsibleSection(
                        title: "Servers",
                        subtitle: statusSummary(monitoringService.servers),
                        isExpanded: expandedSections.contains("servers")
                    ) {
                        if monitoringService.servers.isEmpty {
                            Text("No servers available")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ServersListWidget(
                                servers: monitoringService.servers,
                                services: monitoringService.services,
                                monitoringService: monitoringService
                            )
                        }
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        toggleSection("servers")
                    }
                    
                    // Services Section
                    CollapsibleSection(
                        title: "Services",
                        subtitle: statusSummary(monitoringService.services),
                        isExpanded: expandedSections.contains("services")
                    ) {
                        if monitoringService.services.isEmpty {
                            Text("No services available")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ServicesWidget(
                                services: monitoringService.services,
                                servers: monitoringService.servers
                            )
                        }
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        toggleSection("services")
                    }
                    
                    // VMs Section
                    CollapsibleSection(
                        title: "Virtual Machines",
                        subtitle: statusSummary(monitoringService.virtualMachines),
                        isExpanded: expandedSections.contains("vms")
                    ) {
                        if monitoringService.virtualMachines.isEmpty {
                            Text("No virtual machines available")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            VMsWidget(
                                vms: monitoringService.virtualMachines,
                                servers: monitoringService.servers,
                                monitoringService: monitoringService
                            )
                        }
                    }
                    .padding(.horizontal)
                    .onTapGesture {
                        toggleSection("vms")
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
