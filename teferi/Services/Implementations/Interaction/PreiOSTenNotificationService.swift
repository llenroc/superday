import Foundation
import RxSwift
import UIKit

class PreiOSTenNotificationService : NotificationService
{
    //MARK: Private Properties
    private let loggingService : LoggingService
    private let settingsService : SettingsService
    private let timeService : TimeService
    private var notificationSubscription : Disposable?
    private let notificationAuthorizedObservable : Observable<Void>
    
    //MARK: Initializers
    init(loggingService: LoggingService, settingsService: SettingsService, timeService: TimeService, _ notificationAuthorizedObservable: Observable<Void>)
    {
        self.loggingService = loggingService
        self.settingsService = settingsService
        self.timeService = timeService
        self.notificationAuthorizedObservable = notificationAuthorizedObservable
    }
    
    //MARK: Public Methods
    func requestNotificationPermission(completed: @escaping () -> ())
    {
        let notificationSettings = UIUserNotificationSettings(types: [ .alert, .sound, .badge ], categories: nil)
        
        notificationSubscription =
            notificationAuthorizedObservable
                .subscribe(onNext: completed)
        
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
    }
    
    func scheduleNormalNotification(date: Date, title: String, message: String)
    {
        scheduleNotification(date: date, title: title, message: message, ofType: .normal)
    }
    
    func unscheduleAllNotifications(completion: (() -> Void)?, ofTypes types: NotificationType?...)
    {
        UIApplication.shared.cancelAllLocalNotifications()
        completion?()
    }
    
    func clearAndScheduleAllDefaultNotifications()
    {
        unscheduleAllNotifications(completion: { [unowned self] in
            self.scheduleVotingNotifications()
            self.scheduleWeeklyRatingNotifications()
        }, ofTypes: .repeatWeekly)
    }
    
    //MARK: Private Methods
    
    private func scheduleVotingNotifications()
    {
        guard let installDate = settingsService.installDate else { return }
        
        for i in 2...7
        {
            if timeService.now.ignoreTimeComponents() == installDate.ignoreTimeComponents(), timeService.now.dayOfWeek == i-1 { continue }
            
            let date = Date.create(weekday: i, hour: Constants.hourToShowDailyVotingUI, minute: 00, second: 00)
            scheduleNotification(date: date, title: L10n.votingNotificationTittle, message: L10n.votingNotificationMessage, ofType: .repeatWeekly)
        }
    }
    
    private func scheduleWeeklyRatingNotifications()
    {
        guard
            let installDate = settingsService.installDate,
            timeService.now.timeIntervalSince(installDate) >= Constants.sevenDaysInSeconds
        else { return }
        
        let date = Date.create(weekday: 1, hour: Constants.hourToShowWeeklyRatingUI, minute: 00, second: 00)
        scheduleNotification(date: date, title: L10n.ratingNotificationTitle, message: L10n.ratingNotificationMessage, ofType: .repeatWeekly)
    }
    
    private func scheduleNotification(date: Date, title: String, message: String, ofType type: NotificationType)
    {
        loggingService.log(withLogLevel: .info, message: "Scheduling message for date: \(date)")
        
        let notification = UILocalNotification()
        notification.userInfo = ["id": type.rawValue + "\(date.dayOfWeek)\(date.hour)\(date.minute)\(date.second)", "notificationType": type.rawValue]
        notification.fireDate = date
        notification.alertTitle = title
        notification.alertBody = message
        notification.alertAction = L10n.appName
        notification.soundName = UILocalNotificationDefaultSoundName
        
        if type == .repeatWeekly
        {
            notification.repeatInterval = .weekOfYear
        }
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
}
