import SwiftUI
import Firebase
import UserNotifications

@main
struct PawFinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request notification permission when app launches
                    notificationManager.requestPermission()
                    
                    // Set notification delegate
                    UNUserNotificationCenter.current().delegate = notificationManager
                    
                    // Schedule daily motivation notification
                    notificationManager.scheduleDailyMotivationNotification()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle notification actions when app is not running
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }
}
