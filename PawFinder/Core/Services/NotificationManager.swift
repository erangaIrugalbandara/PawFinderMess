import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate { // Inherit from NSObject
    static let shared = NotificationManager()
    
    private override init() {} // Ensure singleton pattern
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied")
                }
                
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func scheduleThankYouNotification(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Thank You, Community Hero!"
        content.body = "You just helped save \(petName)'s life! 🐾 The pet owner has been notified of your sighting report. You're making a real difference! 💕"
        content.sound = .default
        content.badge = 1
        
        // Add custom user info for analytics or actions
        content.userInfo = [
            "type": "sighting_success",
            "petName": petName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Create trigger for immediate delivery (1 second delay to ensure smooth transition)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "sighting_thank_you_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Thank you notification scheduled for \(petName)")
            }
        }
    }
    
    func scheduleDelayedHeroNotification(petName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🦸‍♀️ You're a Pet Hero!"
        content.body = "Your sighting report for \(petName) is helping their family right now. Every report brings pets closer to home! 🏠✨"
        content.sound = .default
        
        content.userInfo = [
            "type": "hero_reminder",
            "petName": petName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Schedule for 30 seconds later as a follow-up
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30.0, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "hero_reminder_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule hero notification: \(error.localizedDescription)")
            } else {
                print("✅ Hero reminder notification scheduled for \(petName)")
            }
        }
    }
    
    func scheduleDailyMotivationNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🐾 Help Find Lost Pets Today"
        content.body = "Check if there are any lost pets in your area that need your help! Every sighting matters. 💖"
        content.sound = .default
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_motivation",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily notification: \(error.localizedDescription)")
            } else {
                print("✅ Daily motivation notification scheduled")
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "sighting_success", "hero_reminder":
                // Could navigate to specific screen or show additional info
                print("🎯 User tapped on sighting success notification")
            default:
                break
            }
        }
        
        completionHandler()
    }
}
