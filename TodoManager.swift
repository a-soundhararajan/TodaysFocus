import Foundation
import SwiftUI
import UserNotifications

class TodoManager: ObservableObject {
    static let shared = TodoManager()
    
    @Published var todos: [TodoItem] = []
    @Published var selectedCategory: Category? = nil
    @Published var showCompleted: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let todosKey = "todos"
    
    init() {
        loadTodos()
        // Set up notification categories immediately
        DispatchQueue.main.async {
            self.setupNotificationCategories()
            self.requestNotificationPermissions()
        }
    }
    
    var filteredTodos: [TodoItem] {
        var filtered = todos
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        return filtered.sorted { first, second in
            // First, move completed items to the bottom
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            
            // For incomplete items, sort by due date first (ignoring time)
            if let firstDate = first.dueDate, let secondDate = second.dueDate {
                let firstDateOnly = Calendar.current.startOfDay(for: firstDate)
                let secondDateOnly = Calendar.current.startOfDay(for: secondDate)
                if firstDateOnly != secondDateOnly {
                    return firstDateOnly < secondDateOnly
                }
            }
            
            // If due dates are the same or both nil, sort by priority (High > Medium > Low)
            let firstPriorityWeight = priorityWeight(for: first.priority)
            let secondPriorityWeight = priorityWeight(for: second.priority)
            
            if firstPriorityWeight != secondPriorityWeight {
                return firstPriorityWeight > secondPriorityWeight
            }
            
            // If one has due date and other doesn't, prioritize the one with due date
            if first.dueDate != nil && second.dueDate == nil {
                return true
            }
            if first.dueDate == nil && second.dueDate != nil {
                return false
            }
            
            // Finally sort by creation date (newest first)
            return first.createdAt > second.createdAt
        }
    }
    
    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        todos.count
    }
    
    func addTodo(_ todo: TodoItem) {
        todos.append(todo)
        saveTodos()
        scheduleReminder(for: todo)
    }
    
    func deleteTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            // Cancel notification before deleting
            cancelReminder(for: todo)
            todos.remove(at: index)
            saveTodos()
        }
    }
    
    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            if todos[index].isCompleted {
                todos[index].completedAt = Date()
            } else {
                todos[index].completedAt = nil
            }
            saveTodos()
        }
    }
    
    func updateTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            // Cancel existing notification if any
            cancelReminder(for: todos[index])
            todos[index] = todo
            saveTodos()
            // Schedule new notification if reminder is set
            scheduleReminder(for: todo)
        }
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            userDefaults.set(encoded, forKey: todosKey)
        }
    }
    
    private func loadTodos() {
        if let data = userDefaults.data(forKey: todosKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }
    
    func clearCompleted() {
        todos.removeAll { $0.isCompleted }
        saveTodos()
    }
    
    func getTodosDueToday() -> [TodoItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let dueDateStart = Calendar.current.startOfDay(for: dueDate)
            return dueDateStart >= today && dueDateStart < tomorrow
        }
    }
    
    func getTodosDueThisWeek() -> [TodoItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let dueDateStart = calendar.startOfDay(for: dueDate)
            return dueDateStart >= weekStart && dueDateStart < weekEnd
        }
    }
    
    func getTodosByCategory(_ category: Category) -> [TodoItem] {
        let filtered = todos.filter { $0.category == category }
        return filtered.sorted { first, second in
            if first.isCompleted != second.isCompleted {
                return !first.isCompleted
            }
            if let firstDate = first.dueDate, let secondDate = second.dueDate {
                let firstDateOnly = Calendar.current.startOfDay(for: firstDate)
                let secondDateOnly = Calendar.current.startOfDay(for: secondDate)
                if firstDateOnly != secondDateOnly {
                    return firstDateOnly < secondDateOnly
                }
            }
            let firstPriorityWeight = priorityWeight(for: first.priority)
            let secondPriorityWeight = priorityWeight(for: second.priority)
            if firstPriorityWeight != secondPriorityWeight {
                return firstPriorityWeight > secondPriorityWeight
            }
            if first.dueDate != nil && second.dueDate == nil {
                return true
            }
            if first.dueDate == nil && second.dueDate != nil {
                return false
            }
            return first.createdAt > second.createdAt
        }
    }
    
    private func priorityWeight(for priority: Priority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    func getOverdueTodos() -> [TodoItem] {
        let now = Date()
        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return !todo.isCompleted && dueDate < now
        }
    }
    
    private func scheduleReminder(for todo: TodoItem) {
        guard let reminderDate = todo.reminderDate, reminderDate > Date(), todo.reminderEnabled else { 
            print("Reminder not scheduled: date=\(todo.reminderDate?.description ?? "nil"), enabled=\(todo.reminderEnabled)")
            return 
        }
        
        // Cancel any existing notifications for this todo
        cancelReminder(for: todo)
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder: \(todo.title)"
        content.body = todo.description.isEmpty ? "You have a task reminder." : todo.description
        content.sound = .default
        content.categoryIdentifier = "TODO_REMINDER"
        content.userInfo = ["todoId": todo.id.uuidString]
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)
        
        print("Scheduling main reminder for: \(todo.title) at \(reminderDate)")
        
        // Schedule the main reminder
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule main notification: \(error)")
            } else {
                print("Successfully scheduled main notification for: \(todo.title)")
                
                // Schedule nagging reminder only after main reminder is scheduled
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.scheduleNaggingReminder(for: todo, originalDate: reminderDate)
                }
            }
        }
    }
    
    private func scheduleNaggingReminder(for todo: TodoItem, originalDate: Date) {
        let nagContent = UNMutableNotificationContent()
        nagContent.title = "Nagging Reminder: \(todo.title)"
        nagContent.body = "You still have this task pending."
        nagContent.sound = .default
        nagContent.categoryIdentifier = "TODO_REMINDER"
        nagContent.userInfo = ["todoId": todo.id.uuidString]
        if #available(iOS 15.0, *) {
            nagContent.interruptionLevel = .timeSensitive
            nagContent.relevanceScore = 0.8
        }
        
        let nagDate = Calendar.current.date(byAdding: .minute, value: 10, to: originalDate) ?? originalDate
        let nagTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nagDate)
        let nagTrigger = UNCalendarNotificationTrigger(dateMatching: nagTriggerDate, repeats: false)
        let nagRequest = UNNotificationRequest(identifier: "nag-\(todo.id.uuidString)", content: nagContent, trigger: nagTrigger)
        
        print("Scheduling nagging reminder for: \(todo.title) at \(nagDate)")
        
        UNUserNotificationCenter.current().add(nagRequest) { error in
            if let error = error {
                print("Failed to schedule nagging notification: \(error)")
            } else {
                print("Successfully scheduled nagging notification for: \(todo.title)")
            }
        }
    }
    
    private func cancelReminder(for todo: TodoItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todo.id.uuidString, "nag-\(todo.id.uuidString)"])
    }
    
    func snoozeReminder(for todoId: UUID, minutes: Int) {
        guard let index = todos.firstIndex(where: { $0.id == todoId }) else { return }
        
        // Cancel existing notification
        cancelReminder(for: todos[index])
        
        // Update reminder date
        let newReminderDate = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date()
        todos[index].reminderDate = newReminderDate
        todos[index].reminderEnabled = true
        
        saveTodos()
        
        // Schedule new notification
        scheduleReminder(for: todos[index])
    }
    
    func turnOffReminder(for todoId: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == todoId }) else { return }
        
        // Cancel existing notification
        cancelReminder(for: todos[index])
        
        // Turn off reminder
        todos[index].reminderEnabled = false
        
        saveTodos()
    }
    
    func setupNotificationCategories() {
        print("Setting up notification categories...")
        
        let snooze15Action = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "Snooze 15 min",
            options: [.foreground, .authenticationRequired, .destructive]
        )
        
        let snooze30Action = UNNotificationAction(
            identifier: "SNOOZE_30",
            title: "Snooze 30 min",
            options: [.foreground, .authenticationRequired, .destructive]
        )
        
        let snooze60Action = UNNotificationAction(
            identifier: "SNOOZE_60",
            title: "Snooze 1 hour",
            options: [.foreground, .authenticationRequired, .destructive]
        )
        
        let turnOffAction = UNNotificationAction(
            identifier: "TURN_OFF",
            title: "Turn Off",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "TODO_REMINDER",
            actions: [snooze15Action, snooze30Action, snooze60Action, turnOffAction],
            intentIdentifiers: [],
            options: [.allowAnnouncement]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("Successfully set notification categories")
        
        // Verify categories were set
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            print("Available categories: \(categories.count)")
            for category in categories {
                print("Category: \(category.identifier) with \(category.actions.count) actions")
                for action in category.actions {
                    print("  - Action: \(action.identifier) - \(action.title)")
                }
            }
        }
    }
    
    func testNotification() {
        print("Scheduling test notification...")
        
        // Force refresh notification categories
        setupNotificationCategories()
        
        let content = UNMutableNotificationContent()
        content.title = "Test Reminder"
        content.body = "This is a test notification with actions"
        content.sound = .default
        content.categoryIdentifier = "TODO_REMINDER"
        content.userInfo = ["test": "true"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification failed: \(error)")
            } else {
                print("Test notification scheduled successfully")
                print("Notification category: \(content.categoryIdentifier)")
                
                // Check pending notifications
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("Pending notifications: \(requests.count)")
                    for request in requests {
                        print("  - ID: \(request.identifier), Category: \(request.content.categoryIdentifier)")
                    }
                }
            }
        }
    }
    
    func forceRefreshNotificationCategories() {
        print("Force refreshing notification categories...")
        setupNotificationCategories()
    }
    
    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification Settings:")
            print("  - Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("  - Alert Setting: \(settings.alertSetting.rawValue)")
            print("  - Badge Setting: \(settings.badgeSetting.rawValue)")
            print("  - Sound Setting: \(settings.soundSetting.rawValue)")
            print("  - Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
            print("  - Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
        }
    }
    
    // MARK: - Weekly Wins Methods
    
    func getWeeklyWinsForCurrentMonth() -> [WeeklyWin] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the current month
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else {
            return []
        }
        
        var weeklyWins: [WeeklyWin] = []
        
        // Get all weeks in the current month
        var currentWeekStart = monthStart
        var weekNumber = 1
        
        while currentWeekStart <= now {
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)!
            
            // Get completed tasks for this week
            let completedTasks = todos.filter { todo in
                guard todo.isCompleted, let completionDate = todo.completedAt else { return false }
                return completionDate >= currentWeekStart && completionDate < weekEnd
            }
            
            let weekWin = WeeklyWin(
                weekNumber: weekNumber,
                weekStart: currentWeekStart,
                weekEnd: weekEnd,
                completedTasks: completedTasks,
                totalTasks: completedTasks.count
            )
            
            weeklyWins.append(weekWin)
            
            // Move to next week
            currentWeekStart = weekEnd
            weekNumber += 1
        }
        
        return weeklyWins
    }
    
    func getWeeklyWinsSummary() -> WeeklyWinsSummary {
        let weeklyWins = getWeeklyWinsForCurrentMonth()
        let totalCompleted = weeklyWins.reduce(0) { $0 + $1.completedTasks.count }
        let averagePerWeek = weeklyWins.isEmpty ? 0 : Double(totalCompleted) / Double(weeklyWins.count)
        let bestWeek = weeklyWins.max { $0.completedTasks.count < $1.completedTasks.count }
        
        return WeeklyWinsSummary(
            totalWeeks: weeklyWins.count,
            totalCompleted: totalCompleted,
            averagePerWeek: averagePerWeek,
            bestWeek: bestWeek
        )
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permissions granted")
                } else {
                    print("Notification permissions denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

// MARK: - Weekly Win Models

struct WeeklyWin: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let weekStart: Date
    let weekEnd: Date
    let completedTasks: [TodoItem]
    let totalTasks: Int
    
    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
    
    var weekTitle: String {
        return "Week \(weekNumber)"
    }
}

struct WeeklyWinsSummary {
    let totalWeeks: Int
    let totalCompleted: Int
    let averagePerWeek: Double
    let bestWeek: WeeklyWin?
    
    var bestWeekTitle: String {
        guard let bestWeek = bestWeek else { return "N/A" }
        return "Week \(bestWeek.weekNumber) (\(bestWeek.completedTasks.count) tasks)"
    }
}

