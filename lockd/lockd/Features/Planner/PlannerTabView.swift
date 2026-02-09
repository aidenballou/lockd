import SwiftUI

struct PlannerTabView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.appTheme) private var theme

    private let liveActivityCoordinator = LiveActivityCoordinator()

    @State private var showingAddTask = false
    @State private var showingCreateTemplate = false
    @State private var showConfetti = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.tokens.spacing.unit * 2) {
                    header
                    currentAndNextSection
                    timelineSection
                    templatesSection
                    historySection
                }
                .padding(.horizontal, theme.tokens.spacing.screenHorizontal)
                .padding(.vertical, theme.tokens.spacing.unit * 2)
            }
            .background(theme.tokens.colors.bgSecondary)
            .navigationTitle("Daily Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lock In") {
                        showingAddTask = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskSheet {
                    store.addTask(
                        title: $0.title,
                        category: $0.category,
                        notes: $0.notes,
                        start: $0.start,
                        end: $0.end,
                        priority: $0.priority,
                        sourceType: .manual
                    )
                }
                .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateSheet { name in
                    store.createTemplate(name: name, from: store.selectedDay)
                }
                .environment(\.appTheme, theme)
            }
            .overlay {
                if showConfetti {
                    ConfettiBurstView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                syncLiveActivity()
            }
            .onChange(of: store.currentTask?.id) { _, _ in
                syncLiveActivity()
            }
            .onChange(of: store.nextTask?.id) { _, _ in
                syncLiveActivity()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Day")
            DatePicker(
                "Select Day",
                selection: Binding(
                    get: { store.selectedDay },
                    set: { store.updateSelectedDay($0) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            HStack(spacing: theme.tokens.spacing.unit) {
                Button("Apply Template") {
                    if let template = store.dayTemplates.first {
                        store.applyTemplate(template, to: store.selectedDay)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Create Template") {
                    showingCreateTemplate = true
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Inject Habits") {
                    store.acceptHabitSuggestions(for: store.selectedDay)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var currentAndNextSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Current Flow")
            AppCard {
                VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
                    Text("CURRENT")
                        .font(theme.tokens.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.tokens.colors.textSecondary)
                    if let current = store.currentTask {
                        taskIdentityRow(task: current)
                    } else {
                        Text("No active task. Lock in your next block.")
                            .font(theme.tokens.typography.bodySmall)
                            .foregroundStyle(theme.tokens.colors.textSecondary)
                    }

                    Divider()
                        .overlay(theme.tokens.colors.divider)

                    Text("NEXT")
                        .font(theme.tokens.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.tokens.colors.textSecondary)
                    if let next = store.nextTask {
                        taskIdentityRow(task: next)
                    } else {
                        Text("No next task queued.")
                            .font(theme.tokens.typography.bodySmall)
                            .foregroundStyle(theme.tokens.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Timeline")

            if store.plannerTasksForSelectedDay.isEmpty {
                AppCard {
                    Text("No tasks yet. Add your first block.")
                        .font(theme.tokens.typography.bodySmall)
                        .foregroundStyle(theme.tokens.colors.textSecondary)
                }
            } else {
                VStack(spacing: theme.tokens.spacing.unit) {
                    ForEach(store.plannerTasksForSelectedDay) { task in
                        PlannerTaskRow(task: task, hasConflict: store.taskOverlaps(for: task)) {
                            store.completeTask(task.id)
                            HapticManager.mediumImpact()
                            withAnimation(.easeOut(duration: theme.celebration.standardDuration)) {
                                showConfetti = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + theme.celebration.springDuration) {
                                showConfetti = false
                            }
                        }
                    }
                }
            }
        }
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Templates")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.tokens.spacing.unit) {
                    ForEach(store.dayTemplates) { template in
                        AppCard {
                            VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
                                Text(template.name)
                                    .font(theme.tokens.typography.h3)
                                    .foregroundStyle(theme.tokens.colors.textPrimary)
                                Text("\(template.tasks.count) blocks")
                                    .font(theme.tokens.typography.bodySmall)
                                    .foregroundStyle(theme.tokens.colors.textSecondary)
                                Button("Apply") {
                                    store.applyTemplate(template, to: store.selectedDay)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                            .frame(width: 220, alignment: .leading)
                        }
                        .frame(width: 220)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "History")
            ForEach(store.plannerHistory.prefix(7)) { day in
                AppCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                .font(theme.tokens.typography.body.weight(.semibold))
                                .foregroundStyle(theme.tokens.colors.textPrimary)
                            Text("\(day.completedTasks) of \(day.totalTasks) complete")
                                .font(theme.tokens.typography.bodySmall)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        }
                        Spacer()
                        Text(PerformanceMetricFormatter.percent(day.completionRate))
                            .font(theme.tokens.typography.metric)
                            .foregroundStyle(day.completionRate >= 1 ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary)
                    }
                }
            }
        }
    }

    private func taskIdentityRow(task: PlannerTask) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(theme.tokens.typography.body.weight(.semibold))
                .foregroundStyle(theme.tokens.colors.textPrimary)
            Text("\(task.start.formatted(date: .omitted, time: .shortened)) - \(task.end.formatted(date: .omitted, time: .shortened))")
                .font(theme.tokens.typography.bodySmall)
                .foregroundStyle(theme.tokens.colors.textSecondary)
        }
    }

    private func syncLiveActivity() {
        liveActivityCoordinator.startOrUpdate(current: store.currentTask, next: store.nextTask)
        let todayKey = Calendar.current.startOfDay(for: Date())
        let hasActiveTasks = store.tasksByDay[todayKey, default: []].contains { !$0.isCompleted }
        liveActivityCoordinator.endIfNeeded(hasActiveTasks: hasActiveTasks)
    }
}

private struct PlannerTaskRow: View {
    let task: PlannerTask
    let hasConflict: Bool
    let onToggleComplete: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: theme.tokens.spacing.unit) {
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(task.isCompleted ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(theme.tokens.typography.body.weight(.semibold))
                        .foregroundStyle(theme.tokens.colors.textPrimary)
                        .strikethrough(task.isCompleted, color: theme.tokens.colors.textSecondary)

                    Text(task.category)
                        .font(theme.tokens.typography.caption)
                        .foregroundStyle(theme.tokens.colors.textSecondary)

                    Text("\(task.start.formatted(date: .omitted, time: .shortened)) - \(task.end.formatted(date: .omitted, time: .shortened))")
                        .font(theme.tokens.typography.bodySmall)
                        .foregroundStyle(theme.tokens.colors.textSecondary)

                    if hasConflict {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Schedule conflict")
                        }
                        .font(theme.tokens.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.tokens.colors.textPrimary)
                    }
                }

                Spacer()

                PillLabel(text: task.priority.rawValue.uppercased(), success: task.isCompleted)
            }
        }
    }
}

private struct TaskDraft {
    var title: String = ""
    var category: String = "Work"
    var notes: String = ""
    var start: Date = Date()
    var end: Date = Date().addingTimeInterval(3600)
    var priority: TaskPriority = .medium

    var hasInvalidTimeRange: Bool {
        end <= start
    }
}

private struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var draft = TaskDraft()

    let onSave: (TaskDraft) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("DETAILS") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Task Name")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Add title", text: $draft.title)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Add category", text: $draft.category)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Optional", text: $draft.notes)
                    }
                }

                Section("SCHEDULE") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        DatePicker("", selection: $draft.start)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("End")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        DatePicker("", selection: $draft.end)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Priority")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        Picker("Priority", selection: $draft.priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.rawValue.capitalized).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if draft.hasInvalidTimeRange {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("End time must be after start time")
                        }
                        .font(theme.tokens.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.tokens.colors.textPrimary)
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.hasInvalidTimeRange)
                }
            }
        }
    }
}

private struct CreateTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var name: String = ""
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("TEMPLATE") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Template Name")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Add name", text: $name)
                    }
                }
            }
            .navigationTitle("Create Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
