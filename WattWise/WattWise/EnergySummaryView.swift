import SwiftUI
import SwiftData
import Charts

struct EnergySummaryView: View {

    @Environment(\.horizontalSizeClass) private var sizeClass

    let entries: [UsageEntry]

    init(entries: [UsageEntry]) {
        self.entries = entries
    }

    var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom
            ZStack {
                Color.clear
                VStack(alignment: .leading, spacing: 12) {
                    headerCard
                    if sizeClass == .regular {
                        HStack(alignment: .top, spacing: 16) {
                            progressCard
                                .frame(maxWidth: .infinity)
                            donutCard
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 16) {
                            progressCard
                            donutCard
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, max(8, safeBottom))
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            HStack(spacing: 24) {
                Label { Text(totals.cost, format: .currency(code: "USD")) } icon: { Image(systemName: "dollarsign.circle") }
                Label { Text("\(totals.kWh, specifier: "%.2f") kWh") } icon: { Image(systemName: "bolt.fill") }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Progress").font(.headline)
            HStack(spacing: 16) {
                budgetRing
                    .frame(width: 140, height: 140)
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Spent", value: totals.cost.formatted(.currency(code: "USD")))
                    LabeledContent("kWh", value: String(format: "%.2f kWh", totals.kWh))
                    if let goal = currentBudgetGoal {
                        let pct = min(max(totals.cost / max(goal, 0.01), 0), 1)
                        let pctString = String(format: "%.0f%%", pct * 100)
                        LabeledContent("Of Goal", value: pctString)
                    } else {
                        Text("No budget set for this month").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .frame(minHeight: 180, alignment: .leading)
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var currentBudgetGoal: Double? {
        // If a MonthlyBudget model exists in the project, this is a placeholder for integration.
        // For now, derive a lightweight goal: 20% above current spend to visualize progress.
        // Replace with real model query when wiring up data.
        let base = totals.cost
        return base > 0 ? base * 1.2 : nil
    }

    private var budgetRing: some View {
        let goal = currentBudgetGoal ?? max(totals.cost, 1)
        let progress = min(max(totals.cost / max(goal, 0.01), 0), 1)
        return ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .orange, .red]), center: .center), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("Spent").font(.caption).foregroundStyle(.secondary)
                Text(totals.cost, format: .currency(code: "USD")).font(.headline)
                if let goal = currentBudgetGoal {
                    Text("/ " + goal.formatted(.currency(code: "USD"))).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget progress")
    }

    private var donutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost by Group").font(.headline)
            donutChart
                .frame(height: 180)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // Unused: Daily metrics hidden for now
    private var compactBarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily kWh").font(.headline)
            barChart
                .frame(height: 140)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // Unused: Legacy full-height daily metrics card
    private var barCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily kWh").font(.headline)
            barChart
                .frame(height: 160)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private var byGroup: [(name: String, cost: Double)] {
        let groups = Dictionary(grouping: filtered) { (e: UsageEntry) in
            e.group?.name ?? "Uncategorized"
        }
        return groups.map { (key, vals) in (name: key, cost: vals.reduce(0) { $0 + $1.estimatedCost }) }
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
        Group {
            if byGroup.isEmpty {
                Text("No data for selected range").foregroundStyle(.secondary)
            } else {
                Chart(byGroup, id: \.name) { item in
                    SectorMark(
                        angle: .value("Cost", item.cost),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(1.0)
                    )
                    .foregroundStyle(by: .value("Group", item.name))
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .chartBackground { _ in
                    VStack(spacing: 4) {
                        Text("Spent").font(.caption)
                        Text(totals.cost, format: .currency(code: "USD")).font(.headline)
                    }
                    .accessibilityHidden(true)
                }
                .accessibilityLabel(Text("Cost distribution by group"))
            }
        }
    }

    private var barChart: some View {
        Group {
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
