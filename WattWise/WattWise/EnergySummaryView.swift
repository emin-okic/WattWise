import SwiftUI
import SwiftData
import Charts

struct EnergySummaryView: View {

    let entries: [UsageEntry]

    init(entries: [UsageEntry]) {
        self.entries = entries
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                donutChart
                barChart
            }
            .padding()
        }
    }

    private var filtered: [UsageEntry] {
        let now = Date()
        let cal = Calendar.current
        if let start = cal.date(from: cal.dateComponents([.year, .month], from: now)),
           let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start)?.endOfDay(cal) {
            return entries.filter { $0.timestamp >= start && $0.timestamp <= end }
        }
        return entries
    }

    private var totals: (kWh: Double, cost: Double) {
        filtered.reduce((0, 0)) { acc, e in
            (acc.0 + e.kWh, acc.1 + e.estimatedCost)
        }
    }

    private var byAppliance: [(appliance: Appliance, cost: Double)] {
        Dictionary(grouping: filtered, by: { $0.appliance })
            .map { (key, vals) in (appliance: key, cost: vals.reduce(0) { $0 + $1.estimatedCost }) }
            .sorted { $0.cost > $1.cost }
    }

    private var byDay: [(date: Date, kWh: Double)] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { e in
            cal.startOfDay(for: e.timestamp)
        }
        return groups.map { (key, vals) in (date: key, kWh: vals.reduce(0) { $0 + $1.kWh }) }
            .sorted { $0.date < $1.date }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Month").font(.title2.bold())
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Total Spent").font(.caption).foregroundStyle(.secondary)
                    Text(totals.cost, format: .currency(code: "USD")).font(.title3.weight(.semibold))
                }
                VStack(alignment: .leading) {
                    Text("Total kWh").font(.caption).foregroundStyle(.secondary)
                    Text("\(totals.kWh, specifier: "%.2f") kWh").font(.title3.weight(.semibold))
                }
            }
        }
    }

    private var donutChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cost by Appliance").font(.headline)
            if byAppliance.isEmpty {
                Text("No data for selected range").foregroundStyle(.secondary)
            } else {
                Chart(byAppliance, id: \.appliance) { item in
                    SectorMark(
                        angle: .value("Cost", item.cost),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1.0)
                    )
                    .foregroundStyle(by: .value("Appliance", item.appliance.rawValue))
                }
                .frame(height: 220)
                .chartLegend(position: .bottom, alignment: .leading)
                .chartBackground { _ in
                    VStack(spacing: 4) {
                        Text("Spent").font(.caption)
                        Text(totals.cost, format: .currency(code: "USD")).font(.headline)
                    }
                    .accessibilityHidden(true)
                }
                .accessibilityLabel(Text("Cost distribution by appliance"))
            }
        }
    }

    private var barChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily kWh").font(.headline)
            if byDay.isEmpty {
                Text("No data for selected range").foregroundStyle(.secondary)
            } else {
                Chart(byDay, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("kWh", item.kWh)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }
                .chartYAxis {
                    AxisMarks()
                }
                .accessibilityLabel(Text("Daily energy usage in kilowatt-hours"))
            }
        }
    }
}

private extension Date {
    func endOfDay(_ calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: self)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? self
    }
}

#Preview {
    let container = try! ModelContainer(for: UsageEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    // Seed some preview data
    let cal = Calendar.current
    let now = Date()
    let days = (0..<10).compactMap { cal.date(byAdding: .day, value: -$0, to: now) }
    for d in days {
        let e1 = UsageEntry(timestamp: d, appliance: .dishwasher, kWh: Double.random(in: 0.8...1.6), pricePerkWh: 0.14)
        let e2 = UsageEntry(timestamp: d, appliance: .washer, kWh: Double.random(in: 0.4...1.0), pricePerkWh: 0.14)
        context.insert(e1)
        context.insert(e2)
    }
    return EnergySummaryView(entries: try! context.fetch(FetchDescriptor<UsageEntry>()))
        .modelContainer(container)
}
