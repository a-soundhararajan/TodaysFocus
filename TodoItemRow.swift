import SwiftUI

struct TodoItemRow: View {
    @EnvironmentObject var todoManager: TodoManager
    let todo: TodoItem
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    todoManager.toggleTodo(todo)
                }
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(todo.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(todo.isCompleted)
                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    // Priority indicator
                    Image(systemName: todo.priority.icon)
                        .font(.caption)
                        .foregroundColor(Color(todo.priority.color))
                }
                
                if !todo.description.isEmpty {
                    Text(todo.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: todo.category.icon)
                            .font(.caption2)
                        Text(todo.category.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(todo.category.color).opacity(0.2))
                    .foregroundColor(Color(todo.category.color))
                    .cornerRadius(8)
                    
                    // Due date
                    if let dueDate = todo.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption2)
                        }
                        .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }
                    
                    // Reminder indicator
                    if let reminderDate = todo.reminderDate, todo.reminderEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                            Text(reminderDate, style: .time)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            }
            
            // Detail button
            Button(action: {
                showingDetail = true
            }) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            TodoDetailView(todo: todo)
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !todo.isCompleted
    }
}

struct TodoDetailView: View {
    @EnvironmentObject var todoManager: TodoManager
    @Environment(\.presentationMode) var presentationMode
    let todo: TodoItem
    @State private var editedTodo: TodoItem
    
    init(todo: TodoItem) {
        self.todo = todo
        self._editedTodo = State(initialValue: todo)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $editedTodo.title)
                    
                    TextField("Description", text: $editedTodo.description)
                }
                
                Section(header: Text("Priority")) {
                    HStack(spacing: 12) {
                        ForEach(Priority.allCases, id: \.self) { priorityOption in
                            Button(action: {
                                editedTodo.priority = priorityOption
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: priorityOption.icon)
                                        .font(.title2)
                                        .foregroundColor(editedTodo.priority == priorityOption ? .white : Color(priorityOption.color))
                                    
                                    Text(priorityOption.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(editedTodo.priority == priorityOption ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(editedTodo.priority == priorityOption ? Color.green : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(priorityOption.color), lineWidth: 2)
                                )
                                .scaleEffect(editedTodo.priority == priorityOption ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: editedTodo.priority)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $editedTodo.category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(category.color))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { editedTodo.dueDate ?? Date() },
                            set: { editedTodo.dueDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    Button("Remove Due Date") {
                        editedTodo.dueDate = nil
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Reminder")) {
                    Toggle("Enable reminder", isOn: $editedTodo.reminderEnabled)
                    
                    if editedTodo.reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: { editedTodo.reminderDate ?? Date() },
                                set: { editedTodo.reminderDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        Button("Remove Reminder") {
                            editedTodo.reminderDate = nil
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Delete Task") {
                        todoManager.deleteTodo(todo)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(id: "todoDetailToolbar") {
                ToolbarItem(id: "cancel", placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(id: "save", placement: .navigationBarTrailing) {
                    Button("Save") {
                        todoManager.updateTodo(editedTodo)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(editedTodo.title.isEmpty)
                }
            }
        }
    }
} 