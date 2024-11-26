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
                    Text("Current Ping")
                    Spacer()
                    Text("\(Int(service.lastPing))ms")
                }
                
                HStack {
                    Text("Server")
                    Spacer()
                    Text(server.name)
                }
            }
            
            Section("Ping History") {
                Chart {
                    ForEach(Array(service.pingHistory.enumerated()), id: \.offset) { index, ping in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Ping", ping)
                        )
                        .foregroundStyle(service.status.color)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .padding(.vertical)
            }
        }
        .navigationTitle(service.name)
    }
} 