# TodaysFocus
A beautiful and feature-rich iOS Todo application built with SwiftUI. This app provides a modern, intuitive interface for managing tasks with advanced features like categories, priorities, due dates, and comprehensive statistics.
## Features

### 🎯 Core Features
- **Task Management**: Create, edit, delete, and mark tasks as complete
- **Categories**: Organize tasks into Personal, Work, Shopping, Health, and Education categories
- **Priorities**: Set Low, Medium, or High priority levels with visual indicators
- **Due Dates**: Add optional due dates with overdue detection
- **Search**: Find tasks quickly with real-time search functionality
- **Filtering**: Filter tasks by category and completion status

### 📊 Statistics & Analytics
- **Overview Dashboard**: View total, completed, pending, and overdue tasks
- **Category Breakdown**: See progress for each category with visual progress bars
- **Priority Analysis**: Track tasks by priority level
- **Recent Activity**: Monitor recent task changes
- **Completion Rates**: Track your productivity with completion percentages

### 🎨 Modern UI/UX
- **Tabbed Interface**: Easy navigation between Tasks, Categories, Statistics, and Settings
- **Swipe Actions**: Swipe to delete tasks quickly
- **Visual Indicators**: Color-coded categories and priority levels
- **Responsive Design**: Optimized for all iOS devices
- **Dark Mode Support**: Automatic adaptation to system appearance

### ⚙️ Settings & Data Management
- **Display Preferences**: Toggle completed task visibility
- **Data Export**: Export all tasks as text for backup
- **Bulk Operations**: Clear completed tasks or all tasks
- **Statistics Overview**: View detailed app usage statistics

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clean separation of concerns
- **UserDefaults**: Local data persistence
- **Codable**: JSON serialization for data storage

### Requirements
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd TodaysFocus
   ```

2. **Open in Xcode**:
   ```bash
   open TodaysFocus.xcodeproj
   ```

3. **Build and Run**:
   - Select your target device or simulator
   - Press `Cmd + R` to build and run the app

## Project Structure

```
TodaysFocus/
├── TodaysFocus.swift          # App entry point
├── ContentView.swift            # Main tab view
├── TodoItem.swift               # Data model
├── TodoManager.swift            # Business logic & data persistence
├── TodoListView.swift           # Main task list
├── TodoItemRow.swift            # Individual task row
├── AddTodoView.swift            # Add new task form
├── CategoriesView.swift         # Category management
├── StatisticsView.swift         # Analytics dashboard
├── SettingsView.swift           # App settings
├── Info.plist                   # App configuration
└── README.md                    # This file
```

## Usage

### Adding Tasks
1. Tap the "+" button on the Tasks tab
2. Fill in the task details (title, description, priority, category, due date)
3. Tap "Add" to save the task

### Managing Tasks
- **Complete**: Tap the circle next to a task
- **Edit**: Tap on a task to open the detail view
- **Delete**: Swipe left on a task and tap "Delete"

### Filtering Tasks
- Use the category chips at the top to filter by category
- Use the search bar to find specific tasks
- Toggle "Show completed tasks" in Settings

### Viewing Statistics
- Navigate to the Statistics tab to see:
  - Overview cards with key metrics
  - Category breakdown with progress bars
  - Priority distribution
  - Recent activity feed

## Data Persistence

The app uses `UserDefaults` to store task data locally on the device. All tasks are automatically saved and restored when the app launches.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with SwiftUI and modern iOS development practices
- Icons from SF Symbols
- Design inspired by modern iOS app guidelines

## Support

If you encounter any issues or have questions, please open an issue on GitHub or contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: December 2024 
