import Foundation
import ActivityKit
import os.log

enum LiveActivityManager {
    private static let log = Logger(subsystem: "WattWise", category: "LiveActivity")

    @MainActor static func startOrUpdateToday(usedKWh: Double, dailyBudgetKWh: Double, enablePush: Bool = false) async {
        log.debug("Live Activity authorization: areActivitiesEnabled = \((ActivityAuthorizationInfo().areActivitiesEnabled))")
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            log.debug("Live Activities not authorized")
            return
        }
        endActivitiesNotForToday()
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: DateComponents(day: 1, second: -1), to: todayStart) ?? Date().addingTimeInterval(12 * 60 * 60)

        /* todayStart defined above */

        if let existing = Activity<EnergyBudgetAttributes>.activities.first(where: { Calendar.current.isDate($0.attributes.dayStart, inSameDayAs: todayStart) }) {
            log.debug("Updating existing Live Activity id: \((existing.id))")
            await update(existing, usedKWh: usedKWh, dailyBudgetKWh: dailyBudgetKWh)
            return
        }

        let attributes = EnergyBudgetAttributes(dayStart: todayStart)
        let state = EnergyBudgetAttributes.ContentState(usedKWh: usedKWh, dailyBudgetKWh: dailyBudgetKWh)
        do {
            let content = ActivityContent(state: state, staleDate: endOfDay)
            let activity = try Activity.request(attributes: attributes, content: content, pushType: enablePush ? .token : nil)
            log.debug("Started Live Activity id: \((activity.id))")

            if enablePush {
                Task.detached {
                    for await tokenData in activity.pushTokenUpdates {
                        let token = tokenData.map { String(format: "%02x", $0) }.joined()
                        log.debug("Live Activity push token: \(token, privacy: .private)")
                        // TODO: send token to your server for remote updates
                    }
                }
            }
        } catch {
            log.error("Failed to start activity: \(String(describing: error))")
        }
    }

    @MainActor static func update(_ activity: Activity<EnergyBudgetAttributes>, usedKWh: Double, dailyBudgetKWh: Double) async {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: DateComponents(day: 1, second: -1), to: todayStart) ?? Date().addingTimeInterval(12 * 60 * 60)
        log.debug("Updating Live Activity id: \((activity.id)) used=\(usedKWh) budget=\(dailyBudgetKWh)")
        let state = EnergyBudgetAttributes.ContentState(usedKWh: usedKWh, dailyBudgetKWh: dailyBudgetKWh)
        let content = ActivityContent(state: state, staleDate: endOfDay)
        do {
            try await activity.update(content)
        } catch {
            log.error("Failed to update activity: \(String(describing: error))")
        }
    }

    static func endActivitiesNotForToday() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        Activity<EnergyBudgetAttributes>.activities.forEach { activity in
            if !Calendar.current.isDate(activity.attributes.dayStart, inSameDayAs: todayStart) {
                Task { await activity.end(dismissalPolicy: .immediate) }
            }
        }
    }
}
