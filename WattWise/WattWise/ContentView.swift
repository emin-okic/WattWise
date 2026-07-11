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

    @State private var showingAddUsageEntry = false
    @State private var spendGoal: Double = 100.0

    private var spent: Double {
        entries.reduce(0) { $0 + $1.estimatedCost }
    }

    var body: some View {
        TabView {
            // Summary Tab
            NavigationStack {
                EnergySummaryView(entries: entries)
                    .navigationTitle("Summary")
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
                    BudgetBannerView(spendGoal: spendGoal, spent: spent)
                    SpendGoalInput(spendGoal: $spendGoal)
                    transactionsList
                }
                .padding(.horizontal)
                .navigationTitle("Transactions")
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
            ForEach(entries) { entry in
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

                    Text(entry.timestamp, style: .date)
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
            for index in offsets {
                modelContext.delete(entries[index])
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
    @Binding var spendGoal: Double

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

            // Using a TextField with currency formatter, left aligned $ inside the field via formatter
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
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UsageEntry.self, inMemory: true)
}
