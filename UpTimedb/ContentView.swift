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
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 20) {
                    if monitoringService.isSimulated {
                        OverallStatusWidget(monitoringService: monitoringService)
                            .padding(.horizontal)
                        
                        ServersWidget(servers: monitoringService.servers,
                                    services: monitoringService.services,
                                    monitoringService: monitoringService)
                            .padding(.horizontal)
                        
                        ServicesWidget(services: monitoringService.services,
                                     servers: monitoringService.servers)
                            .padding(.horizontal)
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
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
}
