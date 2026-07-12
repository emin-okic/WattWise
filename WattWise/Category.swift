import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var name: String
    var iconSystemName: String
    var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \UsageEntry.category)
    var entries: [UsageEntry] = []

    init(name: String, iconSystemName: String = "square.grid.2x2", colorHex: String = "#4CAF50") {
        self.name = name
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
    }
}

extension Category {
    static let defaultCategories: [(name: String, icon: String, color: String)] = [
        ("Kitchen", "fork.knife", "#FF7043"),
        ("Bathroom", "shower", "#42A5F5"),
        ("Living Room", "sofa.fill", "#8D6E63"),
        ("Bedroom", "bed.double.fill", "#7E57C2"),
        ("Laundry", "washer.fill", "#26A69A"),
        ("HVAC", "thermometer.sun.fill", "#EF5350"),
        ("Lighting", "lightbulb.fill", "#FFD54F"),
        ("Outdoor", "leaf.fill", "#66BB6A"),
        ("Office", "desktopcomputer", "#29B6F6"),
        ("Garage", "car.fill", "#90A4AE")
    ]

    static func seedDefaultsIfNeeded(in context: ModelContext) throws {
        let fetch = FetchDescriptor<Category>()
        let existing = try context.fetch(fetch)
        if existing.isEmpty {
            for def in defaultCategories {
                let c = Category(name: def.name, iconSystemName: def.icon, colorHex: def.color)
                context.insert(c)
            }
            try context.save()
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexStr = hex
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        guard hexStr.count == 6, let intVal = Int(hexStr, radix: 16) else { return nil }
        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8) & 0xFF) / 255.0
        let b = Double(intVal & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
