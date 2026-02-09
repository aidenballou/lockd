import Charts
import SwiftUI

struct GymTabView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.appTheme) private var theme

    @State private var selectedExercise: String = "Bench Press"
    @State private var showingCardioSheet = false
    @State private var showingWorkoutTemplateSheet = false
    @State private var showingLogSetSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.tokens.spacing.unit * 2) {
                    metrics
                    workoutTemplatesSection
                    progressSection
                    cardioSection
                }
                .padding(.horizontal, theme.tokens.spacing.screenHorizontal)
                .padding(.vertical, theme.tokens.spacing.unit * 2)
            }
            .background(theme.tokens.colors.bgSecondary)
            .navigationTitle("Gym")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log Cardio") {
                        showingCardioSheet = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .sheet(isPresented: $showingCardioSheet) {
                AddCardioSheet { log in
                    store.addCardioLog(log)
                }
                .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showingWorkoutTemplateSheet) {
                AddWorkoutTemplateSheet { name, exercises in
                    let exerciseModels = exercises.map { name in
                        Exercise(id: UUID(), name: name, targetSets: 4, targetReps: 8)
                    }
                    store.addWorkoutTemplate(name: name, exercises: exerciseModels)
                }
                .environment(\.appTheme, theme)
            }
            .sheet(isPresented: $showingLogSetSheet) {
                LogSetSheet(exerciseName: selectedExercise) { weight, reps, sets in
                    store.logSet(exerciseName: selectedExercise, weight: weight, reps: reps, sets: sets)
                }
                .environment(\.appTheme, theme)
            }
            .onAppear {
                if selectedExercise.isEmpty, let first = store.exerciseTrends.keys.sorted().first {
                    selectedExercise = first
                }
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: theme.tokens.spacing.unit) {
            MetricBadge(label: "Workout Days", value: "\(store.workoutTemplates.count)")
            MetricBadge(label: "Cardio Logs", value: "\(store.cardioLogs.count)", success: !store.cardioLogs.isEmpty)
        }
    }

    private var workoutTemplatesSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Workout Days")

            Button("Create Workout Day") {
                showingWorkoutTemplateSheet = true
            }
            .buttonStyle(SecondaryButtonStyle())

            ForEach(store.workoutTemplates) { template in
                AppCard {
                    VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
                        HStack {
                            Text(template.name)
                                .font(theme.tokens.typography.h3)
                                .foregroundStyle(theme.tokens.colors.textPrimary)
                            Spacer()
                            Text("\(template.exercises.count) exercises")
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(template.exercises.prefix(3)) { exercise in
                                Text("• \(exercise.name) \(exercise.targetSets)x\(exercise.targetReps)")
                                    .font(theme.tokens.typography.bodySmall)
                                    .foregroundStyle(theme.tokens.colors.textSecondary)
                            }
                        }

                        Button("Schedule In Planner") {
                            store.scheduleWorkout(templateID: template.id, for: store.selectedDay)
                            HapticManager.mediumImpact()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Progress")

            AppCard {
                VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(store.exerciseTrends.keys.sorted(), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("Log Set") {
                        showingLogSetSheet = true
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    let trend = store.trend(for: selectedExercise)
                    if trend.isEmpty {
                        Text("No trend data yet. Log your first set.")
                            .font(theme.tokens.typography.bodySmall)
                            .foregroundStyle(theme.tokens.colors.textSecondary)
                    } else {
                        Chart(trend) { point in
                            LineMark(
                                x: .value("Day", point.day),
                                y: .value("Top Set", point.topSetWeight)
                            )
                            .foregroundStyle(theme.tokens.colors.textPrimary)
                            .lineStyle(StrokeStyle(lineWidth: 3))

                            PointMark(
                                x: .value("Day", point.day),
                                y: .value("Top Set", point.topSetWeight)
                            )
                            .foregroundStyle(point.isPersonalRecord ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary)
                            .symbolSize(point.isPersonalRecord ? 65 : 40)
                        }
                        .frame(height: 180)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4))
                        }

                        if let latest = trend.last {
                            HStack {
                                Text("Top Set")
                                    .font(theme.tokens.typography.caption)
                                    .foregroundStyle(theme.tokens.colors.textSecondary)
                                Spacer()
                                Text(PerformanceMetricFormatter.weight(latest.topSetWeight))
                                    .font(theme.tokens.typography.body.weight(.semibold))
                                    .foregroundStyle(theme.tokens.colors.textPrimary)
                            }

                            HStack {
                                Text("Volume")
                                    .font(theme.tokens.typography.caption)
                                    .foregroundStyle(theme.tokens.colors.textSecondary)
                                Spacer()
                                Text(PerformanceMetricFormatter.volume(latest.totalVolume))
                                    .font(theme.tokens.typography.body.weight(.semibold))
                                    .foregroundStyle(theme.tokens.colors.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var cardioSection: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit) {
            SectionHeader(title: "Cardio")

            if store.cardioLogs.isEmpty {
                AppCard {
                    Text("No cardio logs yet. Log your first session.")
                        .font(theme.tokens.typography.bodySmall)
                        .foregroundStyle(theme.tokens.colors.textSecondary)
                }
            }

            ForEach(store.cardioLogs) { log in
                AppCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.machine.rawValue)
                                .font(theme.tokens.typography.body.weight(.semibold))
                                .foregroundStyle(theme.tokens.colors.textPrimary)
                            Spacer()
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        }

                        Text("\(log.durationMinutes) min")
                            .font(theme.tokens.typography.bodySmall)
                            .foregroundStyle(theme.tokens.colors.textSecondary)

                        switch log.machine {
                        case .treadmill:
                            Text("Speed \(PerformanceMetricFormatter.decimal(log.speed)) | Incline \(PerformanceMetricFormatter.decimal(log.incline))")
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        case .stairmaster:
                            Text("Level \(log.level)")
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        case .bike, .other:
                            Text("Speed \(PerformanceMetricFormatter.decimal(log.speed))")
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

private struct AddCardioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var machine: CardioMachine = .treadmill
    @State private var durationMinutes: Int = 20
    @State private var speed: Double = 6
    @State private var incline: Double = 2
    @State private var level: Int = 5

    let onSave: (CardioLog) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("DETAILS") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Machine")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        Picker("Machine", selection: $machine) {
                            ForEach(CardioMachine.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 5...120, step: 5)
                }

                Section("METRICS") {
                    if machine == .treadmill || machine == .bike || machine == .other {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Speed")
                                .font(theme.tokens.typography.caption.weight(.semibold))
                            Slider(value: $speed, in: 0...12, step: 0.1)
                            Text(PerformanceMetricFormatter.decimal(speed))
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        }
                    }

                    if machine == .treadmill {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Incline")
                                .font(theme.tokens.typography.caption.weight(.semibold))
                            Slider(value: $incline, in: 0...15, step: 0.5)
                            Text(PerformanceMetricFormatter.decimal(incline))
                                .font(theme.tokens.typography.caption)
                                .foregroundStyle(theme.tokens.colors.textSecondary)
                        }
                    }

                    if machine == .stairmaster {
                        Stepper("Level: \(level)", value: $level, in: 1...20)
                    }
                }
            }
            .navigationTitle("Log Cardio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        onSave(
                            CardioLog(
                                id: UUID(),
                                date: Date(),
                                machine: machine,
                                durationMinutes: durationMinutes,
                                speed: speed,
                                incline: incline,
                                level: level
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AddWorkoutTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var name = ""
    @State private var exercisesText = ""
    let onSave: (String, [String]) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("WORKOUT DAY") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Add day name", text: $name)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Exercises (comma separated)")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        TextField("Bench Press, Incline Press", text: $exercisesText)
                    }
                }
            }
            .navigationTitle("Create Workout Day")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        let list = exercisesText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        onSave(name, list)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || exercisesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct LogSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let exerciseName: String
    @State private var weight: Double = 135
    @State private var reps: Int = 8
    @State private var sets: Int = 4

    let onSave: (Double, Int, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("SET LOG") {
                    Text(exerciseName)
                        .font(theme.tokens.typography.body.weight(.semibold))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Weight (lb)")
                            .font(theme.tokens.typography.caption.weight(.semibold))
                        Slider(value: $weight, in: 45...405, step: 5)
                        Text(PerformanceMetricFormatter.weight(weight))
                            .font(theme.tokens.typography.caption)
                            .foregroundStyle(theme.tokens.colors.textSecondary)
                    }
                    Stepper("Reps: \\(reps)", value: $reps, in: 1...20)
                    Stepper("Sets: \\(sets)", value: $sets, in: 1...10)
                }
            }
            .navigationTitle("Log Set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        onSave(weight, reps, sets)
                        dismiss()
                    }
                }
            }
        }
    }
}
