import Foundation

enum TaskSourceType: String, CaseIterable, Codable {
    case manual
    case habit
    case workout
}

enum TaskPriority: String, CaseIterable, Codable {
    case low
    case medium
    case high
}

struct PlannerTask: Identifiable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var notes: String
    var start: Date
    var end: Date
    var priority: TaskPriority
    var sourceType: TaskSourceType
    var completedAt: Date?

    var isCompleted: Bool { completedAt != nil }
}

struct PlannerDaySummary: Identifiable {
    let id = UUID()
    let date: Date
    let totalTasks: Int
    let completedTasks: Int

    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

struct DayTemplate: Identifiable {
    let id: UUID
    var name: String
    var tasks: [TemplateTask]
}

struct TemplateTask: Identifiable {
    let id: UUID
    var title: String
    var category: String
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int
    var priority: TaskPriority
    var sourceType: TaskSourceType
}

enum HabitType: String, CaseIterable {
    case build = "BUILD"
    case remove = "REMOVE"
}

struct Habit: Identifiable {
    let id: UUID
    var name: String
    var type: HabitType
    var weeklyTarget: Int
    var weeklyCompleted: Int
    var currentStreak: Int
    var bestStreak: Int
    var reminderHour: Int
    var reminderMinute: Int

    var isGoalCompleted: Bool {
        weeklyCompleted >= weeklyTarget
    }
}

struct WorkoutTemplate: Identifiable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
}

struct Exercise: Identifiable, Hashable {
    let id: UUID
    var name: String
    var targetSets: Int
    var targetReps: Int
}

struct ExerciseTrendPoint: Identifiable {
    let id = UUID()
    let day: Date
    let topSetWeight: Double
    let totalVolume: Double
    let isPersonalRecord: Bool
}

enum CardioMachine: String, CaseIterable {
    case treadmill = "Treadmill"
    case stairmaster = "Stairmaster"
    case bike = "Bike"
    case other = "Other"
}

struct CardioLog: Identifiable {
    let id: UUID
    var date: Date
    var machine: CardioMachine
    var durationMinutes: Int
    var speed: Double
    var incline: Double
    var level: Int
}

struct Achievement: Identifiable {
    let id: UUID
    let title: String
    let detail: String
    let date: Date
}
