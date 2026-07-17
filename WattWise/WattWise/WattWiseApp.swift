//
//  WattWiseApp.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import SwiftUI
import SwiftData
import ActivityKit
import os.log

@main
struct WattWiseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UsageEntry.self,
            UsageGroup.self,
            MonthlyBudget.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let lifecycle = AppLifecycleHooks()
    @Environment(\.scenePhase) private var scenePhase
    private let log = Logger(subsystem: "WattWise", category: "App")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // End stale activities and prepare for today
                    LiveActivityManager.endActivitiesNotForToday()
                    lifecycle.startObservingDayChange {
                        LiveActivityManager.endActivitiesNotForToday()
                        log.debug("Day changed — ended stale activities")
                    }
                    // Bootstrap today's Live Activity on app launch
                    let context = ModelContext(sharedModelContainer)
                    Task { @MainActor in
                        let orchestrator = EnergyLiveActivityOrchestrator(modelContext: context)
                        await orchestrator.refreshLiveActivityNearRealtime()
                        log.debug("Bootstrapped Live Activity on app launch")
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Refresh today's Live Activity when app becomes active
                let context = ModelContext(sharedModelContainer)
                Task { @MainActor in
                    let orchestrator = EnergyLiveActivityOrchestrator(modelContext: context)
                    await orchestrator.refreshLiveActivityNearRealtime()
                    log.debug("Refreshed Live Activity on app become active")
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

