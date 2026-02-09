import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var selectedDay: Date = Date()
    @Published private(set) var tasksByDay: [Date: [PlannerTask]] = [:]
    @Published var dayTemplates: [DayTemplate] = []
    @Published var habits: [Habit] = []
    @Published var workoutTemplates: [WorkoutTemplate] = []
    @Published var exerciseTrends: [String: [ExerciseTrendPoint]] = [:]
    @Published var cardioLogs: [CardioLog] = []
    @Published var achievements: [Achievement] = []

    private let calendar = Calendar.current

    init() {
        seedData()
    }

    var plannerTasksForSelectedDay: [PlannerTask] {
        tasksByDay[dayKey(for: selectedDay), default: []]
            .sorted { $0.start < $1.start }
    }

    var currentTask: PlannerTask? {
        let now = Date()
        return tasksByDay[dayKey(for: now), default: []]
            .filter { !$0.isCompleted && $0.start <= now && now < $0.end }
            .sorted { $0.start < $1.start }
            .first
    }

    var nextTask: PlannerTask? {
        let now = Date()
        return tasksByDay[dayKey(for: now), default: []]
            .filter { !$0.isCompleted && $0.start > now }
            .sorted { $0.start < $1.start }
            .first
    }

    var plannerHistory: [PlannerDaySummary] {
        tasksByDay
            .map { (date, tasks) in
                PlannerDaySummary(date: date, totalTasks: tasks.count, completedTasks: tasks.filter(\.isCompleted).count)
            }
            .sorted { $0.date > $1.date }
    }

    func addTask(
        title: String,
        category: String,
        notes: String,
        start: Date,
        end: Date,
        priority: TaskPriority,
        sourceType: TaskSourceType = .manual
    ) {
        var tasks = tasksByDay[dayKey(for: start), default: []]
        tasks.append(
            PlannerTask(
                id: UUID(),
                title: title,
                category: category,
                notes: notes,
                start: start,
                end: end,
                priority: priority,
                sourceType: sourceType,
                completedAt: nil
            )
        )
        tasksByDay[dayKey(for: start)] = tasks
    }

    func completeTask(_ taskID: UUID) {
        let key = dayKey(for: selectedDay)
        guard var tasks = tasksByDay[key],
              let idx = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }

        tasks[idx].completedAt = tasks[idx].isCompleted ? nil : Date()
        tasksByDay[key] = tasks
    }

    func updateSelectedDay(_ date: Date) {
        selectedDay = dayKey(for: date)
    }

    func taskOverlaps(for task: PlannerTask) -> Bool {
        let tasks = tasksByDay[dayKey(for: task.start), default: []]
        return tasks.contains {
            $0.id != task.id &&
            max($0.start, task.start) < min($0.end, task.end)
        }
    }

    func applyTemplate(_ template: DayTemplate, to date: Date) {
        let day = dayKey(for: date)
        var tasks = tasksByDay[day, default: []]

        for templateTask in template.tasks {
            if tasks.contains(where: { $0.title == templateTask.title && calendar.component(.hour, from: $0.start) == templateTask.startHour }) {
                continue
            }

            let start = calendar.date(
                bySettingHour: templateTask.startHour,
                minute: templateTask.startMinute,
                second: 0,
                of: day
            ) ?? day
            let end = calendar.date(byAdding: .minute, value: templateTask.durationMinutes, to: start) ?? start

            tasks.append(
                PlannerTask(
                    id: UUID(),
                    title: templateTask.title,
                    category: templateTask.category,
                    notes: "",
                    start: start,
                    end: end,
                    priority: templateTask.priority,
                    sourceType: templateTask.sourceType,
                    completedAt: nil
                )
            )
        }

        tasksByDay[day] = tasks
    }

    func createTemplate(name: String, from day: Date) {
        let sourceTasks = tasksByDay[dayKey(for: day), default: []]
        guard !sourceTasks.isEmpty else { return }

        let templateTasks = sourceTasks.map { task in
            TemplateTask(
                id: UUID(),
                title: task.title,
                category: task.category,
                startHour: calendar.component(.hour, from: task.start),
                startMinute: calendar.component(.minute, from: task.start),
                durationMinutes: Int(task.end.timeIntervalSince(task.start) / 60),
                priority: task.priority,
                sourceType: task.sourceType
            )
        }

        dayTemplates.append(
            DayTemplate(id: UUID(), name: name, tasks: templateTasks)
        )
    }

    func addHabit(name: String, type: HabitType, weeklyTarget: Int) {
        habits.append(
            Habit(
                id: UUID(),
                name: name,
                type: type,
                weeklyTarget: weeklyTarget,
                weeklyCompleted: 0,
                currentStreak: 0,
                bestStreak: 0,
                reminderHour: 8,
                reminderMinute: 0
            )
        )
    }

    func logHabit(_ habitID: UUID, completed: Bool) {
        guard let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        if completed {
            habits[index].weeklyCompleted += 1
            habits[index].currentStreak += 1
            habits[index].bestStreak = max(habits[index].bestStreak, habits[index].currentStreak)
        } else {
            habits[index].currentStreak = 0
        }

        if habits[index].isGoalCompleted {
            achievements.insert(
                Achievement(
                    id: UUID(),
                    title: "Goal Locked",
                    detail: "\(habits[index].name) weekly target complete",
                    date: Date()
                ),
                at: 0
            )
        }
    }

    func suggestHabitTasks(for day: Date) -> [PlannerTask] {
        habits.map { habit in
            let start = calendar.date(bySettingHour: habit.reminderHour, minute: habit.reminderMinute, second: 0, of: dayKey(for: day)) ?? day
            let end = calendar.date(byAdding: .minute, value: 20, to: start) ?? start

            return PlannerTask(
                id: UUID(),
                title: habit.name,
                category: "Habit",
                notes: "Auto-suggested from Habit tab",
                start: start,
                end: end,
                priority: .medium,
                sourceType: .habit,
                completedAt: nil
            )
        }
    }

    func acceptHabitSuggestions(for day: Date) {
        var tasks = tasksByDay[dayKey(for: day), default: []]
        let suggestions = suggestHabitTasks(for: day)
        for suggestion in suggestions where !tasks.contains(where: { $0.title == suggestion.title && $0.category == "Habit" }) {
            tasks.append(suggestion)
        }
        tasksByDay[dayKey(for: day)] = tasks
    }

    func addWorkoutTemplate(name: String, exercises: [Exercise]) {
        workoutTemplates.append(WorkoutTemplate(id: UUID(), name: name, exercises: exercises))
    }

    func logSet(exerciseName: String, weight: Double, reps: Int, sets: Int) {
        let volume = weight * Double(reps * sets)
        let existing = exerciseTrends[exerciseName, default: []]
        let currentPR = existing.map(\.topSetWeight).max() ?? 0
        let point = ExerciseTrendPoint(
            day: Date(),
            topSetWeight: weight,
            totalVolume: volume,
            isPersonalRecord: weight >= currentPR
        )
        exerciseTrends[exerciseName, default: []].append(point)
    }

    func scheduleWorkout(templateID: UUID, for day: Date) {
        guard let template = workoutTemplates.first(where: { $0.id == templateID }) else { return }
        let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayKey(for: day)) ?? day
        let end = calendar.date(byAdding: .minute, value: 70, to: start) ?? start

        addTask(
            title: template.name,
            category: "Workout",
            notes: "Template workout day",
            start: start,
            end: end,
            priority: .high,
            sourceType: .workout
        )
    }

    func addCardioLog(_ log: CardioLog) {
        cardioLogs.insert(log, at: 0)
    }

    func trend(for exerciseName: String) -> [ExerciseTrendPoint] {
        exerciseTrends[exerciseName, default: []]
    }

    private func dayKey(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func seedData() {
        let today = dayKey(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        tasksByDay[today] = [
            PlannerTask(
                id: UUID(),
                title: "Morning Run",
                category: "Fitness",
                notes: "5k easy pace",
                start: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
                end: calendar.date(bySettingHour: 7, minute: 40, second: 0, of: today) ?? today,
                priority: .high,
                sourceType: .manual,
                completedAt: Date()
            ),
            PlannerTask(
                id: UUID(),
                title: "Deep Work Sprint",
                category: "Work",
                notes: "Project scope and shipping tasks",
                start: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? today,
                end: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: today) ?? today,
                priority: .high,
                sourceType: .manual,
                completedAt: nil
            ),
            PlannerTask(
                id: UUID(),
                title: "Upper Body Session",
                category: "Workout",
                notes: "Bench + rows + shoulders",
                start: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today,
                end: calendar.date(bySettingHour: 19, minute: 15, second: 0, of: today) ?? today,
                priority: .medium,
                sourceType: .workout,
                completedAt: nil
            )
        ]

        tasksByDay[tomorrow] = [
            PlannerTask(
                id: UUID(),
                title: "Plan Review",
                category: "Work",
                notes: "Review daily priorities",
                start: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: tomorrow) ?? tomorrow,
                end: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                priority: .medium,
                sourceType: .manual,
                completedAt: nil
            )
        ]

        dayTemplates = [
            DayTemplate(
                id: UUID(),
                name: "Standard Lock-In Day",
                tasks: [
                    TemplateTask(id: UUID(), title: "Hydration", category: "Habit", startHour: 8, startMinute: 0, durationMinutes: 10, priority: .low, sourceType: .habit),
                    TemplateTask(id: UUID(), title: "Focus Block", category: "Work", startHour: 9, startMinute: 0, durationMinutes: 120, priority: .high, sourceType: .manual),
                    TemplateTask(id: UUID(), title: "Lift Session", category: "Workout", startHour: 18, startMinute: 0, durationMinutes: 70, priority: .high, sourceType: .workout)
                ]
            )
        ]

        habits = [
            Habit(id: UUID(), name: "No Late Scrolling", type: .remove, weeklyTarget: 6, weeklyCompleted: 4, currentStreak: 5, bestStreak: 9, reminderHour: 21, reminderMinute: 30),
            Habit(id: UUID(), name: "Read 20 Minutes", type: .build, weeklyTarget: 7, weeklyCompleted: 5, currentStreak: 3, bestStreak: 8, reminderHour: 20, reminderMinute: 0)
        ]

        workoutTemplates = [
            WorkoutTemplate(
                id: UUID(),
                name: "Push Day",
                exercises: [
                    Exercise(id: UUID(), name: "Bench Press", targetSets: 4, targetReps: 6),
                    Exercise(id: UUID(), name: "Incline Dumbbell Press", targetSets: 3, targetReps: 10),
                    Exercise(id: UUID(), name: "Overhead Press", targetSets: 4, targetReps: 8)
                ]
            ),
            WorkoutTemplate(
                id: UUID(),
                name: "Leg Day",
                exercises: [
                    Exercise(id: UUID(), name: "Back Squat", targetSets: 5, targetReps: 5),
                    Exercise(id: UUID(), name: "Romanian Deadlift", targetSets: 4, targetReps: 8),
                    Exercise(id: UUID(), name: "Walking Lunges", targetSets: 3, targetReps: 12)
                ]
            )
        ]

        exerciseTrends = [
            "Bench Press": mockTrend(base: 185, growth: 2),
            "Back Squat": mockTrend(base: 225, growth: 3)
        ]

        cardioLogs = [
            CardioLog(id: UUID(), date: Date(), machine: .treadmill, durationMinutes: 20, speed: 6.2, incline: 3.5, level: 0),
            CardioLog(id: UUID(), date: Date().addingTimeInterval(-86_400), machine: .stairmaster, durationMinutes: 15, speed: 0, incline: 0, level: 8)
        ]
    }

    private func mockTrend(base: Double, growth: Double) -> [ExerciseTrendPoint] {
        (0..<6).map { index in
            let day = calendar.date(byAdding: .day, value: -5 + index, to: Date()) ?? Date()
            let weight = base + Double(index) * growth
            let volume = weight * 14
            return ExerciseTrendPoint(day: day, topSetWeight: weight, totalVolume: volume, isPersonalRecord: index == 5)
        }
    }
}
