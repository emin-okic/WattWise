//
//  WattWiseApp.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import SwiftUI
import SwiftData

@main
struct WattWiseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UsageEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
