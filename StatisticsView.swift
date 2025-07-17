import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var showingWeeklyWinsSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Wins Button
                    Button("Weekly Wins - Current Month") {
                        showingWeeklyWinsSheet = true
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Overview cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Tasks",
                            value: "\(todoManager.totalCount)",
                            icon: "list.bullet",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Completed",
                            value: "\(todoManager.completedCount)",
                            icon: "checkmark.circle",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Pending",
                            value: "\(todoManager.totalCount - todoManager.completedCount)",
                            icon: "clock",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Overdue",
                            value: "\(todoManager.getOverdueTodos().count)",
                            icon: "exclamationmark.triangle",
                            color: .red
                        )
                    }
                    
                    // Category breakdown
                    CategoryBreakdownView()
                    
                    // Priority breakdown
                    PriorityBreakdownView()
                    
                    // Recent activity
                    RecentActivityView()
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingWeeklyWinsSheet) {
                WeeklyWinsView()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CategoryBreakdownView: View {
    @EnvironmentObject var todoManager: TodoManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    CategoryStatRow(category: category)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CategoryStatRow: View {
    @EnvironmentObject var todoManager: TodoManager
    let category: Category
    
    var categoryTodos: [TodoItem] {
        todoManager.getTodosByCategory(category)
    }
    
    var completedCount: Int {
        categoryTodos.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        categoryTodos.count
    }
    
    var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color(category.color).opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundColor(Color(category.color))
            }
            
            // Category name
            Text(category.rawValue)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            // Progress and count
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                    .frame(width: 60)
            }
        }
    }
}

struct PriorityBreakdownView: View {
    @EnvironmentObject var todoManager: TodoManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Priority Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    PriorityStatRow(priority: priority)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PriorityStatRow: View {
    @EnvironmentObject var todoManager: TodoManager
    let priority: Priority
    
    var priorityTodos: [TodoItem] {
        todoManager.todos.filter { $0.priority == priority }
    }
    
    var completedCount: Int {
        priorityTodos.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        priorityTodos.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority icon
            Image(systemName: priority.icon)
                .font(.title3)
                .foregroundColor(Color(priority.color))
                .frame(width: 32)
            
            // Priority name
            Text(priority.rawValue)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            // Count
            Text("\(completedCount)/\(totalCount)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct RecentActivityView: View {
    @EnvironmentObject var todoManager: TodoManager
    
    var recentTodos: [TodoItem] {
        todoManager.todos
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if recentTodos.isEmpty {
                Text("No recent activity")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTodos) { todo in
                        RecentActivityRow(todo: todo)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct RecentActivityRow: View {
    let todo: TodoItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(todo.isCompleted ? .green : .gray)
            
            // Todo info
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                
                Text(todo.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Category badge
            HStack(spacing: 4) {
                Image(systemName: todo.category.icon)
                    .font(.caption2)
                Text(todo.category.rawValue)
                    .font(.caption2)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(todo.category.color).opacity(0.2))
            .foregroundColor(Color(todo.category.color))
            .cornerRadius(8)
        }
    }
} 