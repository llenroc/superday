import Foundation
import UserNotificationsUI

protocol NotificationService
{
    func requestNotificationPermission(completed: @escaping () -> ())
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    
    func unscheduleAllNotifications(completion: (() -> Void)?, ofTypes types: NotificationType?...)
    
    func clearAndScheduleAllDefaultNotifications()
}
