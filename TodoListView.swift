import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var showingAddTodo = false
    @State private var searchText = ""
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    enum HomeSection: Equatable {
        case today
        case week
        case category(Category)
    }
    
    @State private var selectedSection: HomeSection = .today
    
    var filteredTodos: [TodoItem] {
        let baseTodos: [TodoItem]
        
        if searchText.isEmpty {
            switch selectedSection {
            case .today:
                baseTodos = todoManager.getTodosDueToday()
            case .week:
                baseTodos = todoManager.getTodosDueThisWeek()
            case .category(let category):
                baseTodos = todoManager.getTodosByCategory(category)
            }
        } else {
            let searchBase: [TodoItem]
            switch selectedSection {
            case .today:
                searchBase = todoManager.getTodosDueToday()
            case .week:
                searchBase = todoManager.getTodosDueThisWeek()
            case .category(let category):
                searchBase = todoManager.getTodosByCategory(category)
            }
            baseTodos = searchBase.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText) ||
                todo.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        // Always move completed items to the bottom
        return baseTodos.sorted { first, second in
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
    
    var todayStats: (completed: Int, total: Int) {
        let todayTodos = todoManager.getTodosDueToday()
        let completed = todayTodos.filter { $0.isCompleted }.count
        let total = todayTodos.count
        return (completed, total)
    }
    
    var thisWeekStats: (completed: Int, total: Int) {
        let thisWeekTodos = todoManager.getTodosDueThisWeek()
        let completed = thisWeekTodos.filter { $0.isCompleted }.count
        let total = thisWeekTodos.count
        return (completed, total)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                VStack(spacing: 16) {
                    HStack {
                        Text("Today's Focus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(selectedSection == .today ? .blue : .secondary)
                        Spacer()
                        Text("\(todayStats.completed) of \(todayStats.total) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            showingAddTodo = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Filter chips
                    let portraitCategories: [Category] = [.personal, .family, .work]
                    let allCategories: [Category] = [.personal, .family, .work, .learning, .meetUps]
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: selectedSection == .today) {
                                selectedSection = .today
                            }
                            ForEach((verticalSizeClass == .regular ? portraitCategories : allCategories), id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedSection == .category(category),
                                    icon: category.icon
                                ) {
                                    selectedSection = .category(category)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 40)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Todo list
                if filteredTodos.isEmpty {
                    EmptyStateView(isTodayView: selectedSection == .today)
                } else {
                    List {
                        ForEach(filteredTodos) { todo in
                            TodoItemRow(todo: todo)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        todoManager.deleteTodo(todo)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView()
        }
    }
    
    private func priorityWeight(for priority: Priority) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    let isTodayView: Bool
    
    init(isTodayView: Bool = true) {
        self.isTodayView = isTodayView
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isTodayView ? "calendar.badge.clock" : "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(isTodayView ? .blue : .green)
            
            VStack(spacing: 8) {
                Text(isTodayView ? "No tasks due today" : "No tasks yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isTodayView ? "All caught up! No tasks are due today." : "Add your first task to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
} 