import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var showingClearCompletedAlert = false
    @State private var showingClearAllAlert = false
    @State private var showingExportSheet = false
    @State private var showingWeeklyWinsSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Display")) {
                    Toggle("Show completed tasks", isOn: $todoManager.showCompleted)
                    
                    HStack {
                        Text("Default category")
                        Spacer()
                        Picker("Default category", selection: .constant(Category.personal)) {
                            ForEach(Category.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Default priority")
                        Spacer()
                        Picker("Default priority", selection: .constant(Priority.medium)) {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                HStack {
                                    Image(systemName: priority.icon)
                                    Text(priority.rawValue)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button("Clear completed tasks") {
                        showingClearCompletedAlert = true
                    }
                    .foregroundColor(.orange)
                    
                    Button("Clear all tasks") {
                        showingClearAllAlert = true
                    }
                    .foregroundColor(.red)
                    
                    Button("Export tasks") {
                        showingExportSheet = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section(header: Text("Testing")) {
                    Button("Test Notification (5 seconds)") {
                        TodoManager.shared.testNotification()
                    }
                    .foregroundColor(.green)
                    
                    Button("Refresh Notification Categories") {
                        TodoManager.shared.forceRefreshNotificationCategories()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Check Notification Settings") {
                        TodoManager.shared.checkNotificationSettings()
                    }
                    .foregroundColor(.purple)
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Total tasks")
                        Spacer()
                        Text("\(todoManager.totalCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Completed tasks")
                        Spacer()
                        Text("\(todoManager.completedCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Completion rate")
                        Spacer()
                        Text("\(completionRate, specifier: "%.1f")%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Overdue tasks")
                        Spacer()
                        Text("\(todoManager.getOverdueTodos().count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Weekly Wins - Current Month") {
                        showingWeeklyWinsSheet = true
                    }
                    .foregroundColor(.green)
                }
                
                Section(header: Text("Category Management")) {
                    ForEach(Category.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(category.color))
                            Text(category.rawValue)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://a-soundhararajan.github.io/TodaysFocus/privacy-policy.html")!) {
                        HStack {
                            Image(systemName: "hand.raised")
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear Completed Tasks", isPresented: $showingClearCompletedAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    todoManager.clearCompleted()
                }
            } message: {
                Text("This will permanently delete all completed tasks. This action cannot be undone.")
            }
            .alert("Clear All Tasks", isPresented: $showingClearAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    todoManager.todos.removeAll()
                }
            } message: {
                Text("This will permanently delete all tasks. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView()
            }
            .sheet(isPresented: $showingWeeklyWinsSheet) {
                WeeklyWinsView()
            }
        }
    }
    
    private var completionRate: Double {
        guard todoManager.totalCount > 0 else { return 0 }
        return (Double(todoManager.completedCount) / Double(todoManager.totalCount)) * 100
    }
}

struct ExportView: View {
    @EnvironmentObject var todoManager: TodoManager
    @Environment(\.presentationMode) var presentationMode
    
    var exportText: String {
        var text = "Todo App Export\n"
        text += "Generated on: \(Self.dateFormatter.string(from: Date()))\n\n"
        
        for (index, todo) in todoManager.todos.enumerated() {
            text += "\(index + 1). \(todo.title)\n"
            if !todo.description.isEmpty {
                text += "   Description: \(todo.description)\n"
            }
            text += "   Category: \(todo.category.rawValue)\n"
            text += "   Priority: \(todo.priority.rawValue)\n"
            text += "   Status: \(todo.isCompleted ? "Completed" : "Pending")\n"
            if let dueDate = todo.dueDate {
                text += "   Due Date: \(Self.dateFormatter.string(from: dueDate))\n"
            }
            text += "   Created: \(Self.dateFormatter.string(from: todo.createdAt))\n\n"
        }
        
        return text
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(exportText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Export Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let activityVC = UIActivityViewController(activityItems: [exportText], applicationActivities: nil)
                        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

struct WeeklyWinsView: View {
    @EnvironmentObject var todoManager: TodoManager
    @Environment(\.presentationMode) var presentationMode
    
    var weeklyWins: [WeeklyWin] {
        todoManager.getWeeklyWinsForCurrentMonth()
    }
    
    var summary: WeeklyWinsSummary {
        todoManager.getWeeklyWinsSummary()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Card
                    VStack(spacing: 16) {
                        Text("Current Month Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(summary.totalWeeks)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Weeks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(summary.totalCompleted)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text(String(format: "%.1f", summary.averagePerWeek))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("Avg/Week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let bestWeek = summary.bestWeek {
                            VStack(spacing: 4) {
                                Text("Best Week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(bestWeek.weekTitle) (\(bestWeek.completedTasks.count) tasks)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Weekly Breakdown
                    LazyVStack(spacing: 12) {
                        ForEach(weeklyWins) { weekWin in
                            WeeklyWinCard(weekWin: weekWin)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Weekly Wins")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct WeeklyWinCard: View {
    let weekWin: WeeklyWin
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(weekWin.weekTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(weekWin.weekRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(weekWin.completedTasks.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !weekWin.completedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed Tasks:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(weekWin.completedTasks.prefix(3)) { task in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(task.title)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(task.category.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                    
                    if weekWin.completedTasks.count > 3 {
                        Text("+ \(weekWin.completedTasks.count - 3) more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No tasks completed this week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
} 