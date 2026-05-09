import SwiftUI

enum ColorThreshold {
    static func usageColor(for percent: Int, warning: Double, critical: Double) -> Color {
        if Double(percent) >= critical { return .red }
        if Double(percent) >= warning { return .orange }
        return .green
    }
}
