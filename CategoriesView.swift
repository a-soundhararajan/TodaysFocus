import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var todoManager: TodoManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(Category.allCases, id: \.self) { category in
                        CategoryCard(category: category)
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct CategoryCard: View {
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
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: category)) {
            VStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color(category.color).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(Color(category.color))
                }
                
                // Category name
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Task count
                Text("\(completedCount) of \(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Progress bar
                if totalCount > 0 {
                    ProgressView(value: Double(completedCount), total: Double(totalCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                } else {
                    ProgressView(value: 0, total: 1)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryDetailView: View {
    @EnvironmentObject var todoManager: TodoManager
    let category: Category
    @State private var showingAddTodo = false
    
    var categoryTodos: [TodoItem] {
        todoManager.getTodosByCategory(category)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(category.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(categoryTodos.filter { $0.isCompleted }.count) of \(categoryTodos.count) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Only show add button for all categories (since .today and .thisWeek are removed)
                    Button(action: {
                        showingAddTodo = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(Color(category.color))
                    }
                }
                
                // Progress bar
                if categoryTodos.count > 0 {
                    ProgressView(
                        value: Double(categoryTodos.filter { $0.isCompleted }.count),
                        total: Double(categoryTodos.count)
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Todo list
            if categoryTodos.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(Color(category.color).opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("No tasks in \(category.rawValue)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add your first task to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                List {
                    ForEach(categoryTodos.sorted { first, second in
                        if first.isCompleted != second.isCompleted {
                            return !first.isCompleted
                        }
                        return first.createdAt > second.createdAt
                    }) { todo in
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
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView()
        }
    }
} 