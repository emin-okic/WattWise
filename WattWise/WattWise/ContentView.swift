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
    
    @State
    private var showingAddUsageEntry = false

    var body: some View {
        NavigationSplitView {
            
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        showingAddUsageEntry = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $showingAddUsageEntry) {
            AddUsageEntryView()
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
