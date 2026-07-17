import Foundation
import ActivityKit

// Attributes describing a daily energy usage Live Activity
struct EnergyBudgetAttributes: ActivityAttributes {
    // Immutable attributes for a single-day Live Activity instance
    let dayStart: Date // start of the calendar day the activity represents

    // Dynamic content that changes throughout the day
    struct ContentState: Codable, Hashable {
        var usedKWh: Double
        var dailyBudgetKWh: Double

        var progress: Double {
            guard dailyBudgetKWh > 0 else { return 1 }
            return min(max(usedKWh / dailyBudgetKWh, 0), 1)
        }

        var exceeded: Bool { usedKWh > dailyBudgetKWh }
    }
}
