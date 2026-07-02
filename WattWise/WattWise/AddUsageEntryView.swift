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

                Section("Estimated Cost") {

                    Text(
                        estimatedCost,
                        format: .currency(code: "USD")
                    )
                    .font(.title2.bold())

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

                        let entry = UsageEntry(
                            appliance: appliance,
                            kWh: kWh,
                            pricePerkWh: pricePerkWh
                        )

                        modelContext.insert(entry)

                        dismiss()

                    }

                }

            }

        }

    }

}

#Preview {
    AddUsageEntryView()
}
