import SwiftUI
import UserNotifications

@main
struct TodaysFocus: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(TodoManager())
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if let error = error {
                            print("Notification permission error: \(error)")
                        }
                        if granted {
                            TodoManager.shared.setupNotificationCategories()
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "SNOOZE_15":
            TodoManager.shared.snoozeReminder(for: UUID(uuidString: identifier) ?? UUID(), minutes: 15)
        case "SNOOZE_30":
            TodoManager.shared.snoozeReminder(for: UUID(uuidString: identifier) ?? UUID(), minutes: 30)
        case "SNOOZE_60":
            TodoManager.shared.snoozeReminder(for: UUID(uuidString: identifier) ?? UUID(), minutes: 60)
        case "TURN_OFF":
            TodoManager.shared.turnOffReminder(for: UUID(uuidString: identifier) ?? UUID())
        default:
            break
        }
        
        completionHandler()
    }
} 