//
//  ContentView.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case transactions = "Transactions"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [UsageEntry]

    @State private var selectedTab: Tab = .summary
    @State private var showingAddUsageEntry = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                Group {
                    switch selectedTab {
                    case .summary:
                        EnergySummaryView(entries: entries)
                            .transition(.opacity)
                    case .transactions:
                        transactionsList
                    }
                }
            }
            .navigationTitle("WattWise")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .disabled(selectedTab == .summary)
                }
                ToolbarItem {
                    Button {
                        showingAddUsageEntry = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
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
            }
            .onDelete(perform: deleteItems)
        }
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

#Preview {
    ContentView()
        .modelContainer(for: UsageEntry.self, inMemory: true)
}
