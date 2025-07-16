import SwiftUI

struct AddTodoView: View {
    @EnvironmentObject var todoManager: TodoManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Priority = .medium
    @State private var category: Category = .personal
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasReminder = false
    @State private var reminderDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Priority")) {
                    HStack(spacing: 12) {
                        ForEach(Priority.allCases, id: \.self) { priorityOption in
                            Button(action: {
                                priority = priorityOption
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: priorityOption.icon)
                                        .font(.title2)
                                        .foregroundColor(priority == priorityOption ? .white : Color(priorityOption.color))
                                    
                                    Text(priorityOption.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(priority == priorityOption ? .white : .primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(priority == priorityOption ? Color.green : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(priorityOption.color), lineWidth: 2)
                                )
                                .scaleEffect(priority == priorityOption ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: priority)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    let orderedCategories: [Category] = [.personal, .family, .work, .shopping, .learning, .meetUps]
                    Picker("Category", selection: $category) {
                        ForEach(orderedCategories, id: \.self) { category in
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
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section(header: Text("Reminder")) {
                    Toggle("Enable reminder", isOn: $hasReminder)
                    
                    if hasReminder {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(id: "addTodoToolbar") {
                ToolbarItem(id: "cancel", placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(id: "add", placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTodo()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTodo() {
        let todo = TodoItem(
            title: title,
            description: description,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            category: category,
            reminderDate: hasReminder ? reminderDate : nil
        )
        
        todoManager.addTodo(todo)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddTodoView_Previews: PreviewProvider {
    static var previews: some View {
        AddTodoView()
            .environmentObject(TodoManager())
    }
} 