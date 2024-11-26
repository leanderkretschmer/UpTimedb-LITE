import SwiftUI
import Charts

struct ServersWidget: View {
    let servers: [Server]
    let services: [Service]
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Servers")
                .font(.headline)
            
            ForEach(servers) { server in
                ServerCard(server: server, services: services, monitoringService: monitoringService)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ServerCard: View {
    let server: Server
    let services: [Service]
    @ObservedObject var monitoringService: MonitoringService
    
    var body: some View {
        NavigationLink(destination: ServerDetailView(server: server, services: services, monitoringService: monitoringService)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(server.name)
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    StatusIndicator(status: server.status)
                }
                
                Chart {
                    ForEach(Array(server.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(server.status.color)
                    }
                }
                .frame(height: 100)
                
                Text("Current Ping: \(Int(server.lastPing))ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
} 