import SwiftUI
import UIKit

struct HabitsTabView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.appTheme) private var theme

    @State private var showingAddHabit = false
    @State private var milestoneAchievement: Achievement?
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false

    private let shareRenderer = ShareCardRenderer()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.tokens.spacing.unit * 2) {
                    metrics
                    habitsSection
                }
                .padding(.horizontal, theme.tokens.spacing.screenHorizontal)
                .padding(.vertical, theme.tokens.spacing.unit * 2)
            }
            .background(theme.tokens.colors.bgSecondary)
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lock In") {
                        showingAddHabit = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitSheet { name, type, target in
                    store.addHabit(name: name, type: type, weeklyTarget: target)
                }
                .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareImage {
                    ShareSheet(items: [shareImage])
                }
            }
            .onChange(of: store.achievements.count) { oldValue, newValue in
                guard newValue > oldValue, let latest = store.achievements.first else { return }
                milestoneAchievement = latest
                HapticManager.success()
            }
            .overlay {
                if let achievement = milestoneAchievement {
                    MilestonePopup(
                        achievement: achievement,
                        onDismiss: { milestoneAchievement = nil },
                        onShare: {
                            shareImage = shareRenderer.render(
                                title: achievement.title,
                                detail: achievement.detail,
                                style: theme.shareCard
                            )
                            showingShareSheet = true
                        }
                    )
                    .padding(theme.tokens.spacing.screenHorizontal)
                }
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: theme.tokens.spacing.unit) {
            MetricBadge(label: "Active Habits", value: "\(store.habits.count)")
            MetricBadge(
                label: "Goals Hit",
                value: "\(store.habits.filter(\.isGoalCompleted).count)",
                success: store.habits.contains(where: \.isGoalCompleted)
            )
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Progress")

            if store.habits.isEmpty {
                AppCard {
                    Text("No habits yet. Add your first habit.")
                        .font(theme.tokens.typography.bodySmall)
                        .foregroundStyle(theme.tokens.colors.textSecondary)
                }
            }

            ForEach(store.habits) { habit in
                AppCard {
                    HStack(alignment: .center, spacing: theme.tokens.spacing.unit * 2) {
                        HabitProgressRing(progress: min(Double(habit.weeklyCompleted) / Double(max(habit.weeklyTarget, 1)), 1.0), completed: habit.isGoalCompleted)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(habit.name)
                                    .font(theme.tokens.typography.body.weight(.semibold))
                                    .foregroundStyle(theme.tokens.colors.textPrimary)
                                Spacer()
                                PillLabel(text: habit.type.rawValue, success: habit.isGoalCompleted)
                            }

                            Text("\(habit.weeklyCompleted)/\(habit.weeklyTarget) this week")
                                .font(theme.tokens.typography.bodySmall)
                                .foregroundStyle(theme.tokens.colors.textSecondary)

                            Text("Streak \(habit.currentStreak) | Best \(habit.bestStreak)")
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)

                            HStack {
                                if habit.isGoalCompleted {
                                    Button("Complete") {
                                        store.logHabit(habit.id, completed: true)
                                        HapticManager.mediumImpact()
                                    }
                                    .buttonStyle(SuccessButtonStyle())
                                } else {
                                    Button("Complete") {
                                        store.logHabit(habit.id, completed: true)
                                        HapticManager.mediumImpact()
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                }

                                Button("Missed") {
                                    store.logHabit(habit.id, completed: false)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct HabitProgressRing: View {
    let progress: Double
    let completed: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.tokens.colors.border, lineWidth: 7)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(completed ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(PerformanceMetricFormatter.percent(progress))
                .font(theme.tokens.typography.caption.weight(.semibold))
                .foregroundStyle(completed ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary)
        }
        .frame(width: 62, height: 62)
    }
}

private struct MilestonePopup: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    let onShare: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            HStack {
                Text("GOAL LOCKED")
                    .font(theme.tokens.typography.caption.weight(.semibold))
                    .foregroundStyle(theme.tokens.colors.textSecondary)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(theme.tokens.colors.successAccent)
            }

            Text(achievement.title)
                .font(theme.tokens.typography.h2)
                .foregroundStyle(theme.tokens.colors.textPrimary)

            Text(achievement.detail)
                .font(theme.tokens.typography.bodySmall)
                .foregroundStyle(theme.tokens.colors.textSecondary)

            HStack(spacing: theme.tokens.spacing.unit) {
                Button("Share") {
                    onShare()
                }
                .buttonStyle(SuccessButtonStyle())

                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(theme.tokens.spacing.cardPadding)
        .frame(maxWidth: .infinity)
        .background(theme.tokens.colors.bgElevated)
        .overlay(
            RoundedRectangle(cornerRadius: theme.tokens.radius.card)
                .stroke(theme.tokens.colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.tokens.radius.card))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}

private struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var name: String = ""
    @State private var type: HabitType = .build
    @State private var weeklyTarget: Int = 5

    let onSave: (String, HabitType, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("DETAILS") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Habit Name")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Add habit", text: $name)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Type")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        Picker("Type", selection: $type) {
                            ForEach(HabitType.allCases, id: \.self) { option in
                                Text(option.rawValue.capitalized).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weekly Target")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        Stepper("\(weeklyTarget) completions", value: $weeklyTarget, in: 1...14)
                    }
                }
            }
            .navigationTitle("Add Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        onSave(name, type, weeklyTarget)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
