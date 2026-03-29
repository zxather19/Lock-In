import Foundation
import UserNotifications

enum NotificationAuthorizationState: Equatable {
    case unknown
    case notDetermined
    case denied
    case authorized

    var description: String {
        switch self {
        case .unknown:
            return "Checking notification access..."
        case .notDetermined:
            return "Notification access has not been decided yet."
        case .denied:
            return "Notifications are off. Timer completion alerts may not appear."
        case .authorized:
            return "Notifications are enabled."
        }
    }
}

enum NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
        }
    }

    static func authorizationState() async -> NotificationAuthorizationState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .unknown
        }
    }

    static func sendPomodoroEnd(modeName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = "\(modeName) session has ended. Take a break."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
