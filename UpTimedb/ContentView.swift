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
    @State private var expandedSections: Set<String> = ["servers", "services", "vms"]
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 20) {
                    if monitoringService.isSimulated {
                        OverallStatusWidget(monitoringService: monitoringService)
                            .padding(.horizontal)
                        
                        CollapsibleSection(
                            title: "Servers",
                            subtitle: statusSummary(for: monitoringService.servers),
                            isExpanded: expandedSections.contains("servers")
                        ) {
                            ServersListWidget(servers: monitoringService.servers,
                                        services: monitoringService.services,
                                        monitoringService: monitoringService)
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            toggleSection("servers")
                        }
                        
                        CollapsibleSection(
                            title: "Services",
                            subtitle: statusSummary(for: monitoringService.services),
                            isExpanded: expandedSections.contains("services")
                        ) {
                            ServicesWidget(services: monitoringService.services,
                                         servers: monitoringService.servers)
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            toggleSection("services")
                        }
                        
                        CollapsibleSection(
                            title: "Virtual Machines",
                            subtitle: statusSummary(for: monitoringService.virtualMachines),
                            isExpanded: expandedSections.contains("vms")
                        ) {
                            VMsWidget(
                                vms: monitoringService.virtualMachines,
                                servers: monitoringService.servers
                            )
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            toggleSection("vms")
                        }
                    } else {
                        ContentUnavailableView("Simulation Disabled",
                            systemImage: "server.rack",
                            description: Text("Enable simulation in settings to see demo data"))
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
    
    private func statusSummary<T: StatusProvider>(for items: [T]) -> String {
        let online = items.filter { $0.status == .online }.count
        let errors = items.filter { $0.status == .offline }.count
        let warnings = items.filter { $0.status == .warning }.count
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

protocol StatusProvider {
    var status: SystemStatus { get }
}

extension Server: StatusProvider {}
extension Service: StatusProvider {}
extension VirtualMachine: StatusProvider {}

struct CollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String
    let isExpanded: Bool
    let content: () -> Content
    
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
                content()
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
