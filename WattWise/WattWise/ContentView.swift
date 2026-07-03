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
                transactionsList
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
