import Foundation

enum PerformanceMetricFormatter {
    static func percent(_ value: Double) -> String {
        let percent = max(0, min(1, value)) * 100
        return String(format: "%.0f%%", percent)
    }

    static func decimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func weight(_ value: Double) -> String {
        String(format: "%.0f lb", value)
    }

    static func volume(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    static func compactCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
