import SwiftUI
import Charts

struct ServicesWidget: View {
    let services: [Service]
    let servers: [Server]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Services")
                .font(.headline)
            
            ForEach(services) { service in
                ServiceCard(service: service, server: servers.first(where: { $0.id == service.serverId })!)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ServiceCard: View {
    let service: Service
    let server: Server
    
    var body: some View {
        NavigationLink(destination: ServiceDetailView(service: service, server: server)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Running on \(server.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(service.name)
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    StatusIndicator(status: service.status)
                }
                
                Chart {
                    ForEach(Array(service.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(service.status.color)
                    }
                }
                .frame(height: 100)
                
                Text("Current Ping: \(Int(service.lastPing))ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
    }
} 