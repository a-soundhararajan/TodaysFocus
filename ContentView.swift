import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodoListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Tasks")
                }
                .tag(0)
            
            WeekView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Week")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TodoManager())
    }
}

struct WeekView: View {
    @EnvironmentObject var todoManager: TodoManager
    @State private var searchText = ""
    @State private var showingAddTodo = false
    @State private var selectedCategory: Category? = nil
    
    var filteredTodos: [TodoItem] {
        let baseTodos = todoManager.getTodosDueThisWeek()
        let categoryFiltered = selectedCategory == nil ? baseTodos : baseTodos.filter { $0.category == selectedCategory }
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText) ||
                todo.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var weekStats: (completed: Int, total: Int) {
        let weekTodos = todoManager.getTodosDueThisWeek()
        let completed = weekTodos.filter { $0.isCompleted }.count
        let total = weekTodos.count
        return (completed, total)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        Text("Week's Focus")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(weekStats.completed) of \(weekStats.total) completed")
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
                    .padding(.horizontal)
                    
                    // Filter dropdown
                    HStack {
                        Text("Filter by category:")
                            .font(.caption)
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag(Category?.none)
                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(Category?.some(category))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                if filteredTodos.isEmpty {
                    EmptyStateView(isTodayView: false)
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
} 
