//
//  AddDishwasherCycleView.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import SwiftUI
import SwiftData

struct AddUsageEntryView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var appliance: Appliance = .dishwasher

    @State private var kWh = 1.20
    @State private var pricePerkWh = 0.14

    @Query private var categories: [Category]
    @State private var selectedCategory: Category?

    private var estimatedCost: Double {
        kWh * pricePerkWh
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Appliance") {

                    Picker("Appliance", selection: $appliance) {
                        ForEach(Appliance.allCases, id: \.self) { appliance in
                            Text(appliance.rawValue)
                                .tag(appliance)
                        }
                    }
                }

                Section("Energy") {

                    TextField(
                        "Energy Used (kWh)",
                        value: $kWh,
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    TextField(
                        "Electric Rate ($/kWh)",
                        value: $pricePerkWh,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                }

                Section("Category") {
                    Picker("Category", selection: Binding(
                        get: { selectedCategory ?? categories.first(where: { $0.name == "Home" }) },
                        set: { selectedCategory = $0 }
                    )) {
                        ForEach(categories, id: \.persistentModelID) { cat in
                            HStack {
                                Image(systemName: cat.iconSystemName)
                                Text(cat.name)
                            }
                            .tag(cat as Category?)
                        }
                    }
                }

                Section("Estimated Cost") {

                    Text(
                        estimatedCost,
                        format: .currency(code: "USD")
                    )
                    .font(.title2.bold())

                }

            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = categories.first(where: { $0.name == "Home" }) ?? categories.first
                }
            }
            .navigationTitle("Add Usage")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }

                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {

                        // Ensure Home category exists
                        if !categories.contains(where: { $0.name == "Home" }) {
                            let home = Category(name: "Home", iconSystemName: "house.fill", colorHex: "#90CAF9")
                            modelContext.insert(home)
                            try? modelContext.save()
                        }

                        let chosenCategory: Category? = selectedCategory ?? categories.first(where: { $0.name == "Home" })

                        let entry = UsageEntry(
                            appliance: appliance,
                            kWh: kWh,
                            pricePerkWh: pricePerkWh,
                            category: chosenCategory
                        )

                        modelContext.insert(entry)
                        try? modelContext.save()

                        dismiss()

                    }

                }

            }

        }

    }

}

#Preview {
    let container = try! ModelContainer(for: UsageEntry.self, Category.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return AddUsageEntryView().modelContainer(container)
}
