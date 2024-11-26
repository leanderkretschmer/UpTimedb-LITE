import SwiftUI

class ColorSchemeManager: ObservableObject {
    @AppStorage("useSystemColorScheme") var useSystemColorScheme: Bool = true
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    var colorScheme: ColorScheme? {
        if useSystemColorScheme {
            return nil // Use system setting
        } else {
            return isDarkMode ? .dark : .light
        }
    }
} 