import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct PlannerLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentTitle: String
        var nextTitle: String
        var currentTimeRange: String
    }

    var dayLabel: String
}
#endif

final class LiveActivityCoordinator {
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private var activeActivity: Activity<PlannerLiveActivityAttributes>?
    #endif

    func startOrUpdate(current: PlannerTask?, next: PlannerTask?) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *), ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let dayLabel = Date().formatted(date: .abbreviated, time: .omitted)
        let currentTitle = current?.title ?? "No active task"
        let nextTitle = next?.title ?? "No next task"
        let range: String
        if let current {
            range = "\(current.start.formatted(date: .omitted, time: .shortened)) - \(current.end.formatted(date: .omitted, time: .shortened))"
        } else {
            range = ""
        }

        let contentState = PlannerLiveActivityAttributes.ContentState(
            currentTitle: currentTitle,
            nextTitle: nextTitle,
            currentTimeRange: range
        )

        Task {
            if let activity = activeActivity {
                await activity.update(
                    ActivityContent(state: contentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()))
                )
            } else {
                do {
                    let attributes = PlannerLiveActivityAttributes(dayLabel: dayLabel)
                    activeActivity = try Activity.request(
                        attributes: attributes,
                        content: ActivityContent(state: contentState, staleDate: nil),
                        pushType: nil
                    )
                } catch {
                    print("Live Activity start failed: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }

    func endIfNeeded(hasActiveTasks: Bool) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *), !hasActiveTasks else {
            return
        }

        Task {
            if #available(iOS 16.2, *) {
                await activeActivity?.end(nil, dismissalPolicy: .immediate)
            } else {
                await activeActivity?.end(dismissalPolicy: .immediate)
            }
            activeActivity = nil
        }
        #else
        _ = hasActiveTasks
        #endif
    }
}
