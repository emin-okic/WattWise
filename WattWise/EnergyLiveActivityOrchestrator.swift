import Foundation
import SwiftData
import Combine

@MainActor
final class EnergyLiveActivityOrchestrator: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func refreshLiveActivityNearRealtime(now: Date = Date()) async {
        let cal = Calendar.current

        // Day range
        let startOfDay = cal.startOfDay(for: now)
        let endOfDay = cal.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? now

        // Month range (calendar month, inclusive end-of-day)
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let nextMonthStart = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now
        let monthEnd = nextMonthStart.addingTimeInterval(-1) // last second of the current month

        // Fetch UsageEntry for month and day
        let monthDescriptor = FetchDescriptor<UsageEntry>(
            predicate: #Predicate { $0.timestamp >= monthStart && $0.timestamp <= monthEnd }
        )
        let dayDescriptor = FetchDescriptor<UsageEntry>(
            predicate: #Predicate { $0.timestamp >= startOfDay && $0.timestamp <= endOfDay }
        )

        let monthEntries = (try? modelContext.fetch(monthDescriptor)) ?? []
        let dayEntries = (try? modelContext.fetch(dayDescriptor)) ?? []

        // Aggregate today's kWh
        let todaysKWh = dayEntries.reduce(0.0) { $0 + $1.kWh }

        // Fetch MonthlyBudget for this calendar month
        let comps = cal.dateComponents([.year, .month], from: now)
        let budgetFetch: [MonthlyBudget] = (try? modelContext.fetch(
            FetchDescriptor<MonthlyBudget>(predicate: #Predicate { $0.year == comps.year! && $0.month == comps.month! })
        )) ?? []
        let monthlyBudgetUSD = budgetFetch.first?.spendGoal ?? 100.0

        // Compute average $/kWh for the month (fallbacks applied)
        let averageRate: Double = {
            let totalKWh = monthEntries.reduce(0.0) { $0 + $1.kWh }
            let totalCost = monthEntries.reduce(0.0) { $0 + $1.estimatedCost }
            if totalKWh > 0 { return totalCost / totalKWh }
            if let last = monthEntries.last { return last.pricePerkWh }
            return 0.16 // default if no data yet
        }()

        let dailyBudgetKWh = EnergyBudgetCalculator.dailyBudgetKWh(
            monthlyBudgetUSD: monthlyBudgetUSD,
            averageRateUSDPerKWh: averageRate,
            for: now
        )

        await LiveActivityManager.startOrUpdateToday(
            usedKWh: todaysKWh,
            dailyBudgetKWh: dailyBudgetKWh
        )
    }
}

