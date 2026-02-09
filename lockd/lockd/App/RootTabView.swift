import SwiftUI

struct RootTabView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        TabView {
            PlannerTabView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }

            HabitsTabView()
                .tabItem {
                    Label("Habits", systemImage: "checklist")
                }

            GymTabView()
                .tabItem {
                    Label("Gym", systemImage: "dumbbell")
                }

            FutureTabView()
                .tabItem {
                    Label("Future", systemImage: "chart.pie")
                }
        }
        .tint(theme.tokens.colors.textPrimary)
        .background(theme.tokens.colors.bgPrimary)
    }
}
