import SwiftUI
import Charts

struct ServiceDetailView: View {
    let service: Service
    let server: Server
    
    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Current Status")
                    Spacer()
                    StatusIndicator(status: service.status)
                }
                
                HStack {
                    Text("Response Time")
                    Spacer()
                    Text("\(Int(service.lastPing))ms")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Host Server")
                    Spacer()
                    Text(server.name)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Response Time History") {
                Chart {
                    ForEach(Array(service.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(service.status.color)
                    }
                }
                .frame(height: 200)
            }
        }
        .navigationTitle(service.name)
    }
} 