import Foundation

enum EnergyBudgetCalculator {
    static func daysInCalendarMonth(containing date: Date, calendar: Calendar = .current) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    // Convert a monthly dollar budget to a daily kWh budget using an average $/kWh rate.
    static func dailyBudgetKWh(monthlyBudgetUSD: Double,
                               averageRateUSDPerKWh: Double,
                               for date: Date = Date(),
                               calendar: Calendar = .current) -> Double {
        guard monthlyBudgetUSD > 0, averageRateUSDPerKWh > 0 else { return 0 }
        let days = Double(daysInCalendarMonth(containing: date, calendar: calendar))
        let monthlyKWh = monthlyBudgetUSD / averageRateUSDPerKWh
        return monthlyKWh / max(days, 1)
    }

    // Aggregate kWh used today from entries timestamps
    static func todaysKWh(from entries: [UsageEntry], calendar: Calendar = .current, now: Date = Date()) -> Double {
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? now
        return entries.filter { $0.timestamp >= startOfDay && $0.timestamp <= endOfDay }
            .reduce(0) { $0 + $1.kWh }
    }

    // Compute average rate ($/kWh) for the current calendar month from entries
    static func averageRateUSDPerKWhForMonth(from entries: [UsageEntry], date: Date = Date(), calendar: Calendar = .current) -> Double? {
        // Consider only entries in the same calendar month
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return nil }
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? date
        let monthEntries = entries.filter { $0.timestamp >= start && $0.timestamp <= end }
        let totalKWh = monthEntries.reduce(0.0) { $0 + $1.kWh }
        let totalCost = monthEntries.reduce(0.0) { $0 + $1.estimatedCost }
        guard totalKWh > 0 else { return nil }
        return totalCost / totalKWh
    }
}
