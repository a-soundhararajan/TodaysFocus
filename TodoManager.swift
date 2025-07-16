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
        guard let reminderDate = todo.reminderDate, reminderDate > Date(), todo.reminderEnabled else { return }
        
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
        
        // Schedule the main reminder
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Successfully scheduled notification for: \(todo.title)")
            }
        }
        
        // Schedule the nagging reminder (10 minutes later, only once)
        let nagContent = UNMutableNotificationContent()
        nagContent.title = "Nagging Reminder: \(todo.title)"
        nagContent.body = "You still have this task pending."
        nagContent.sound = .default
        nagContent.categoryIdentifier = content.categoryIdentifier
        nagContent.userInfo = content.userInfo
        if #available(iOS 15.0, *) {
            nagContent.interruptionLevel = content.interruptionLevel
            nagContent.relevanceScore = content.relevanceScore
        }
        let nagDate = Calendar.current.date(byAdding: .minute, value: 10, to: reminderDate) ?? reminderDate
        let nagTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nagDate)
        let nagTrigger = UNCalendarNotificationTrigger(dateMatching: nagTriggerDate, repeats: false)
        let nagRequest = UNNotificationRequest(identifier: "nag-\(todo.id.uuidString)", content: nagContent, trigger: nagTrigger)
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
} 