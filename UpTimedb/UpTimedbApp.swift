//
//  UpTimedbApp.swift
//  UpTimedb
//
//  Created by leander kretschmer on 25.11.24.
//

import SwiftUI

@main
struct UpTimedbApp: App {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorSchemeManager.colorScheme)
                .environmentObject(colorSchemeManager)
        }
    }
}
