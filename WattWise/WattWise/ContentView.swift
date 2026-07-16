//
//  ContentView.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [UsageEntry]
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var groups: [UsageGroup]

    @State private var showingAddUsageEntry = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    @State private var showingAddGroupAlert = false
    @State private var newGroupName = ""
    @State private var collapsedGroups: Set<String> = []
    @State private var presentedGroupName: String? = nil
    @State private var showingAnalytics = false

    private var selectedBudget: MonthlyBudget? {
        monthlyBudgets.first { $0.month == selectedMonth && $0.year == selectedYear }
    }

    private var spendGoal: Double {
        selectedBudget?.spendGoal ?? 100.0
    }

    private var spent: Double {
        let cal = Calendar.current
        return entries.filter {
            let comp = cal.dateComponents([.year, .month], from: $0.timestamp)
            return comp.year == selectedYear && comp.month == selectedMonth
        }.reduce(0) { $0 + $1.estimatedCost }
    }

    private var entriesForSelection: [UsageEntry] {
        let cal = Calendar.current
        return entries.filter {
            let comp = cal.dateComponents([.year, .month], from: $0.timestamp)
            return comp.year == selectedYear && comp.month == selectedMonth
        }
    }

    private var defaultGroup: UsageGroup? {
        groups.first { $0.name == "Home" }
    }

    var body: some View {
        // Consolidated Transactions Screen (no nav bar, no tabs)
        List {
            // Header Section: Month picker + Budget banner
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    MonthYearGridPicker(month: $selectedMonth, year: $selectedYear)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    BudgetBannerView(spendGoal: spendGoal, spent: spent)
                        .cardStyle()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Goal Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Monthly Goal", systemImage: "target")
                            .font(.headline)
                        Spacer()
                    }
                    SpendGoalInput(spendGoal: spendGoal) { newGoal in
                        setSpendGoal(newGoal)
                    }
                    .id("goal-\(selectedYear)-\(selectedMonth)")
                }
                .cardContainer()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Transactions Section
            Section(header:
                HStack {
                    Text("Transactions by Group").font(.headline)
                    Spacer()
                    Button {
                        showingAddGroupAlert = true
                    } label: {
                        Label("Add Group", systemImage: "folder.badge.plus")
                            .labelStyle(.iconOnly)
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.accentColor)
                    .accessibilityLabel("Add New Group")
                }
            ) {
                TransactionsGroupedList(
                    entries: entriesForSelection,
                    groups: groups,
                    onDeleteGroup: { name in
                        deleteGroup(named: name)
                    },
                    onAddGroup: { showingAddGroupAlert = true },
                    presentedGroupName: $presentedGroupName,
                    modelContext: modelContext
                )
            }
        }
        .listStyle(.insetGrouped)
        .overlay(alignment: .bottomLeading) {
            VStack(spacing: 12) {
                Button(action: { showingAnalytics = true }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(18)
                        .background(
                            Circle()
                                .fill(Color.purple)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                }
                .accessibilityLabel("Show Analytics")

                Button(action: { showingAddUsageEntry = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(Color.accentColor)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                }
                .accessibilityLabel("Add Energy Transaction")
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            if groups.first(where: { $0.name == "Home" }) == nil {
                let g = UsageGroup(name: "Home")
                modelContext.insert(g)
                try? modelContext.save()
            }
            if groups.first(where: { $0.name == "Uncategorized" }) == nil {
                let u = UsageGroup(name: "Uncategorized")
                modelContext.insert(u)
                try? modelContext.save()
            }
        }
        .alert("New Group", isPresented: $showingAddGroupAlert) {
            TextField("Group name", text: $newGroupName)
            Button("Add") {
                let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                if !groups.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                    modelContext.insert(UsageGroup(name: name))
                    try? modelContext.save()
                }
                newGroupName = ""
            }
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
        } message: {
            Text("Create a room/area category like Kitchen, Bathroom, Living Room.")
        }
        .sheet(isPresented: $showingAddUsageEntry) {
            AddUsageEntryView()
        }
        .sheet(isPresented: $showingAnalytics) {
            EnergySummaryView(entries: entriesForSelection)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let toDelete = offsets.map { entriesForSelection[$0] }
            for item in toDelete {
                modelContext.delete(item)
            }
        }
    }

    private func budget(forMonth month: Int, year: Int) -> MonthlyBudget? {
        monthlyBudgets.first { $0.month == month && $0.year == year }
    }

    private func setSpendGoal(_ goal: Double) {
        if let existing = selectedBudget {
            existing.spendGoal = goal
        } else {
            let new = MonthlyBudget(month: selectedMonth, year: selectedYear, spendGoal: goal)
            modelContext.insert(new)
        }
    }
    
    private func deleteGroup(named name: String) {
        guard let groupToDelete = groups.first(where: { $0.name == name }) else { return }
        guard let unc = groups.first(where: { $0.name == "Uncategorized" }) else { return }
        // Prevent deleting Uncategorized itself
        if groupToDelete.name == "Uncategorized" { return }
        // Reassign entries
        for entry in groupToDelete.entries { entry.group = unc }
        modelContext.delete(groupToDelete)
        try? modelContext.save()
    }
}

fileprivate func icon(for appliance: Appliance) -> String {
    switch appliance {
    case .dishwasher:
        return "fork.knife"
    case .washer:
        return "tshirt"
    }
}

private struct BudgetBannerView: View {
    let spendGoal: Double
    let spent: Double

    private var isOverBudget: Bool {
        spent > spendGoal
    }

    private var bannerColor: LinearGradient {
        if isOverBudget {
            return LinearGradient(
                colors: [.red.opacity(0.8), .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.green.opacity(0.8), .green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var statusIcon: String {
        isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
    }

    private var statusText: String {
        isOverBudget ? "Over Budget" : "Under Budget"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: statusIcon)
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .shadow(radius: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .shadow(radius: 2)

                HStack {
                    Text("Goal:")
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.semibold)
                    Text(spendGoal, format: .currency(code: "USD"))
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Spent:")
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.semibold)
                    Text(spent, format: .currency(code: "USD"))
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
            }
            Spacer()
        }
        .padding()
        .background(bannerColor)
        .cornerRadius(16)
        .shadow(color: isOverBudget ? Color.red.opacity(0.5) : Color.green.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}

private struct SpendGoalInput: View {
    let initialSpendGoal: Double
    @State private var spendGoal: Double
    let onCommit: (Double) -> Void

    init(spendGoal: Double, onCommit: @escaping (Double) -> Void) {
        self.initialSpendGoal = spendGoal
        _spendGoal = State(initialValue: spendGoal)
        self.onCommit = onCommit
    }

    private let formatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        nf.currencySymbol = "$"
        nf.locale = Locale.current
        return nf
    }()

    var body: some View {
        HStack {
            Text("Spend Goal")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            TextField("0", value: $spendGoal, formatter: formatter)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(UIColor.systemGray6))
                )
                .font(.title2.weight(.semibold))
                .frame(minWidth: 100)
                .onChange(of: spendGoal) { newValue in
                    onCommit(newValue)
                }
                .onChange(of: initialSpendGoal) { newValue in
                    // When parent changes month/year, reset the field to the new goal
                    spendGoal = newValue
                }
                .onAppear {
                    // Ensure correct value on initial show
                    spendGoal = initialSpendGoal
                }
        }
    }
}

private struct MonthYearGridPicker: View {
    @Binding var month: Int
    @Binding var year: Int

    @State private var showingPicker = false

    private let months = Calendar.current.monthSymbols
    private let currentYear = Calendar.current.component(.year, from: Date())

    private var titleText: String {
        let name = months[month - 1]
        return "\(name) \(year)"
    }

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 8) {
                Text(titleText)
                    .font(.title2.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            MonthYearGridSheet(month: $month, year: $year)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct MonthYearGridSheet: View {
    @Binding var month: Int
    @Binding var year: Int

    @Environment(\.dismiss) private var dismiss

    private let months = Calendar.current.monthSymbols
    private let currentYear = Calendar.current.component(.year, from: Date())
    @State private var visibleYear: Int = Calendar.current.component(.year, from: Date())
    private let currentMonth: Int = Calendar.current.component(.month, from: Date())

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header with arrows and year centered
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            visibleYear -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(visibleYear, format: .number.grouping(.never))
                        .font(.title2.weight(.bold))

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            visibleYear += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Month grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(1...12, id: \.self) { m in
                        let isSel = (m == month && visibleYear == year)
                        let isCurrent = (m == currentMonth && visibleYear == currentYear)
                        MonthCell(
                            title: months[m - 1].prefix(3).uppercased(),
                            isSelected: isSel
                        ) {
                            month = m
                            year = visibleYear
                            dismiss()
                        }
                        .overlay(
                            // subtle dotted border for non-selected, and filled accent when selected
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: isSel ? 0 : 1, dash: isCurrent ? [4] : []))
                                .foregroundStyle(Color.secondary.opacity(isSel ? 0 : 0.4))
                        )
                    }
                }
                .padding(.horizontal, 16)

                // Footer
                VStack(spacing: 8) {
                    if !(year == currentYear && month == currentMonth) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                month = currentMonth
                                year = currentYear
                                visibleYear = currentYear
                                dismiss()
                            }
                        } label: {
                            Text("Go to Today")
                                .font(.callout.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("You're on the current month")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 8)
            }
            .onAppear {
                visibleYear = year
            }
            //.navigationTitle("Select Month")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct MonthCell: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : .primary)
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    func cardContainer() -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            )
    }
}

private struct TransactionsGroupedList: View {
    let entries: [UsageEntry]
    let groups: [UsageGroup]
    let onDeleteGroup: (String) -> Void
    let onAddGroup: () -> Void
    @Binding var presentedGroupName: String?
    let modelContext: ModelContext

    @State private var internalPresented: String? = nil

    var body: some View {
        let uncategorizedGroup = groups.first { $0.name == "Uncategorized" }
        let normalizedEntries: [UsageEntry] = entries.map { e in
            if e.group == nil, let unc = uncategorizedGroup {
                e.group = unc
            }
            return e
        }
        let grouped = Dictionary(grouping: normalizedEntries) { $0.group?.name ?? "Uncategorized" }
        let sortedSectionNames = grouped.keys.sorted()
        let allGroupNames = Array(Set(sortedSectionNames).union(groups.map { $0.name })).sorted()

        Group {
            ForEach(allGroupNames, id: \.self) { sectionName in
                let sectionItems = grouped[sectionName] ?? []
                let sectionTotal = sectionItems.reduce(0.0) { $0 + $1.estimatedCost }

                Button {
                    presentedGroupName = sectionName
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sectionName)
                                .font(.subheadline.weight(.semibold))
                            Text(sectionTotal, format: .currency(code: "USD"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .if(sectionName != "Uncategorized") { view in
                    view.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteGroup(sectionName)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: Binding(get: { presentedGroupName != nil }, set: { if !$0 { presentedGroupName = nil } })) {
            let name = presentedGroupName ?? ""
            let items = grouped[name] ?? []
            NavigationStack {
                List {
                    ForEach(items) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Label(entry.appliance.rawValue, systemImage: icon(for: entry.appliance))
                                .font(.headline)
                            Text("\(entry.kWh, specifier: "%.2f") kWh")
                            Text(entry.estimatedCost, format: .currency(code: "USD")).foregroundStyle(.green)
                            Text(entry.timestamp.formatted(.dateTime.month(.abbreviated).year()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        withAnimation {
                            let toDelete = offsets.map { items[$0] }
                            for item in toDelete { modelContext.delete(item) }
                        }
                    }
                }
                .navigationTitle(name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { presentedGroupName = nil }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        EditButton()
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UsageEntry.self, inMemory: true)
}

