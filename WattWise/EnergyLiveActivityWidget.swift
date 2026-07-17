import SwiftUI
import WidgetKit
import ActivityKit

struct EnergyBudgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EnergyBudgetAttributes.self) { context in
            // Lock Screen / Banner UI for Live Activity
            let state = context.state
            let progress = state.progress
            let exceeded = state.exceeded

            HStack(spacing: 12) {
                Gauge(value: progress) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(exceeded ? .red : .accentColor)
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Today’s Energy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("\(state.usedKWh, specifier: "%.1f")")
                            .font(.headline)
                        Text("/ \(state.dailyBudgetKWh, specifier: "%.0f") kWh")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .activityBackgroundTint(Color(.secondarySystemBackground))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.usedKWh, specifier: "%.1f") / \(context.state.dailyBudgetKWh, specifier: "%.0f") kWh")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(context.state.exceeded ? .red : .accentColor)
                }
            } compactLeading: {
                Text("\(Int(min(context.state.progress, 1) * 100))%")
            } compactTrailing: {
                Image(systemName: "bolt.fill")
            } minimal: {
                Image(systemName: "bolt.fill")
            }
        }
    }
}
// NOTE: Do not mark this WidgetBundle with @main in the app target.
// If you create a Widget Extension target, move this file there (or add @main there only)
// to avoid multiple @main entry points in the same module.
struct WattWiseWidgets: WidgetBundle {
    var body: some Widget {
        EnergyBudgetLiveActivity()
    }
}
