import SwiftUI

struct FutureTabView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.tokens.spacing.unit * 2) {
                    SectionHeader(title: "Roadmap")

                    AppCard {
                        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
                            Text("Spending & Budgets")
                                .font(theme.tokens.typography.h2)
                                .foregroundStyle(theme.tokens.colors.textPrimary)

                            Text("Bank account connections and budget tracking are next. The foundation is set for secure integrations in Phase 2.")
                                .font(theme.tokens.typography.bodySmall)
                                .foregroundStyle(theme.tokens.colors.textSecondary)

                            HStack(spacing: theme.tokens.spacing.unit) {
                                PillLabel(text: "PHASE 2")
                                PillLabel(text: "PLAID READY", success: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, theme.tokens.spacing.screenHorizontal)
                .padding(.vertical, theme.tokens.spacing.unit * 2)
            }
            .background(theme.tokens.colors.bgSecondary)
            .navigationTitle("Future")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
