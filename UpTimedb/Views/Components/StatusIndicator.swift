import SwiftUI

struct StatusIndicator: View {
    let status: SystemStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)
            Text(status.rawValue)
                .foregroundColor(status.color)
        }
    }
} 