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

    @State private var showingAddUsageEntry = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

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

    var body: some View {
        TabView {
            // Summary Tab
            NavigationStack {
                EnergySummaryView(entries: entriesForSelection)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                showingAddUsageEntry = true
                            } label: {
                                Label("Add Item", systemImage: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Summary", systemImage: "chart.pie")
            }

            // Transactions Tab
            NavigationStack {
                VStack(spacing: 16) {
                    MonthYearGridPicker(month: $selectedMonth, year: $selectedYear)
                    BudgetBannerView(spendGoal: spendGoal, spent: spent)
                    SpendGoalInput(spendGoal: spendGoal) { newGoal in
                        setSpendGoal(newGoal)
                    }
                    transactionsList
                }
                .padding(.horizontal)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddUsageEntry = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("Transactions", systemImage: "list.bullet")
            }
        }
        .sheet(isPresented: $showingAddUsageEntry) {
            AddUsageEntryView()
        }
    }

    private var transactionsList: some View {
        List {
            ForEach(entriesForSelection) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        entry.appliance.rawValue,
                        systemImage: icon(for: entry.appliance)
                    )
                    .font(.headline)

                    Text("\(entry.kWh, specifier: "%.2f") kWh")

                    Text(
                        entry.estimatedCost,
                        format: .currency(code: "USD")
                    )
                    .foregroundStyle(.green)

                    Text(entry.timestamp.formatted(.dateTime.month(.abbreviated).year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let toDelete = offsets.map { entriesForSelection[$0] }
            for item in toDelete {
                modelContext.delete(item)
            }
        }
    }

    private func icon(for appliance: Appliance) -> String {
        switch appliance {
        case .dishwasher:
            return "fork.knife"
        case .washer:
            return "tshirt"
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
    @State private var spendGoal: Double
    let onCommit: (Double) -> Void

    init(spendGoal: Double, onCommit: @escaping (Double) -> Void) {
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

                    Text("\(visibleYear)")
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

                    if year == currentYear && month == currentMonth {
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
            .navigationTitle("Select Month")
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

#Preview {
    ContentView()
        .modelContainer(for: UsageEntry.self, inMemory: true)
}
