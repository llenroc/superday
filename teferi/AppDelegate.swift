import UIKit
import RxSwift
import Foundation
import UserNotifications

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{
    //MARK: Public Properties
    var window: UIWindow?

    //MARK: Private Properties
    fileprivate var dailyVotingNotificationDate : Date? = nil
    private let disposeBag = DisposeBag()
    private let notificationAuthorizedSubject = PublishSubject<Void>()
    
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let loggingService : LoggingService
    private let feedbackService : FeedbackService
    private let locationService : LocationService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    private let trackEventService : TrackEventService
    private let appLifecycleService : AppLifecycleService
    private let notificationService : NotificationService
    private let motionService: MotionService
    private let selectedDateService : DefaultSelectedDateService
    
    private let coreDataStack : CoreDataStack
    
    //MARK: Initializers
    override init()
    {
        timeService = DefaultTimeService()
        metricsService = FabricMetricsService()
        settingsService = DefaultSettingsService(timeService: timeService)
        loggingService = SwiftyBeaverLoggingService()
        appLifecycleService = DefaultAppLifecycleService()
        editStateService = DefaultEditStateService(timeService: timeService)
        locationService = DefaultLocationService(loggingService: loggingService)
        motionService = DefaultMotionService(settingsService: settingsService)
        selectedDateService = DefaultSelectedDateService(timeService: timeService)
        feedbackService = MailFeedbackService(recipients: ["support@toggl.com"], subject: "Superday feedback", body: "")
        
        coreDataStack = CoreDataStack(loggingService: loggingService)
        let timeSlotPersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: TimeSlotModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        let locationPersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: LocationModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        let smartGuessPersistencyService = CoreDataPersistencyService(loggingService: loggingService, modelAdapter: SmartGuessModelAdapter(), managedObjectContext: coreDataStack.managedObjectContext)
        
        smartGuessService = DefaultSmartGuessService(timeService: timeService,
                                                          loggingService: loggingService,
                                                          settingsService: settingsService,
                                                          persistencyService: smartGuessPersistencyService)
        
        timeSlotService = DefaultTimeSlotService(timeService: timeService,
                                                      loggingService: loggingService,
                                                      locationService: locationService,
                                                      persistencyService: timeSlotPersistencyService)
        
        if #available(iOS 10.0, *)
        {
            notificationService = PostiOSTenNotificationService(timeService: timeService,
                                                                     loggingService: loggingService,
                                                                     settingsService: settingsService,
                                                                     timeSlotService: timeSlotService)
        }
        else
        {
            notificationService = PreiOSTenNotificationService(loggingService: loggingService,
                                                               settingsService: settingsService,
                                                               timeService: timeService,
                                                               notificationAuthorizedSubject.asObservable())
        }
        
        let trackEventServicePersistency = TrackEventPersistencyService(loggingService: loggingService,
                                                                        locationPersistencyService: locationPersistencyService)
        
        trackEventService = DefaultTrackEventService(loggingService: loggingService,
                                                          persistencyService: trackEventServicePersistency,
                                                          withEventSources: locationService)
    }
    
    //MARK: UIApplicationDelegate lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        setVersionInSettings()
        setAppearance()
        
        if settingsService.isFirstTimeAppRuns
        {
            settingsService.setShouldAskForNotificationPermission()
        }
        
        if !settingsService.didShowWelcomeMessage
        {
            settingsService.setIsFirstTimeAppRuns()
            settingsService.setIsPostCoreMotionUser()
        }
        
        smartGuessService.purgeEntries(olderThan: timeService.now.add(days: -30))
        
        let isInBackground = launchOptions?[UIApplicationLaunchOptionsKey.location] != nil
        
        logAppStartup(isInBackground)
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            if let notification = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
                dailyVotingNotificationDate = dailyVotingDate(notification)
            }
        }
        
        
        //Faster startup when the app wakes up for location updates
        if isInBackground
        {
            appLifecycleService.publish(.movedToBackground)
            locationService.startLocationTracking()
            return true
        }
        
        initializeWindowIfNeeded()
        
        return true
    }

    private func setVersionInSettings()
    {
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber: String = Bundle.main.object(forInfoDictionaryKey:"CFBundleVersion") as! String
        UserDefaults.standard.set("\(appVersionString) (\(buildNumber))", forKey: "version_string")
    }
    
    private func setAppearance()
    {
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor.white
    }
    
    private func logAppStartup(_ isInBackground: Bool)
    {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let startedOn = isInBackground ? "background" : "foreground"
        let message = "Application started on \(startedOn). App Version: \(versionNumber) Build: \(buildNumber)"


        loggingService.log(withLogLevel: .info, message: message)
    }
    
    private func initializeWindowIfNeeded()
    {
        guard window == nil else { return }
        
        metricsService.initialize()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewModelLocator = DefaultViewModelLocator(timeService: timeService,
                                                       metricsService: metricsService,
                                                       feedbackService: feedbackService,
                                                       locationService: locationService,
                                                       settingsService: settingsService,
                                                       timeSlotService: timeSlotService,
                                                       editStateService: editStateService,
                                                       smartGuessService : smartGuessService,
                                                       appLifecycleService: appLifecycleService,
                                                       selectedDateService: selectedDateService,
                                                       loggingService: loggingService,
                                                       notificationService: notificationService,
                                                       motionService: motionService,
                                                       trackEventService: trackEventService)
        
        window!.rootViewController = IntroPresenter.create(with: viewModelLocator)
        window!.makeKeyAndVisible()
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        appLifecycleService.publish(.movedToBackground)
        locationService.startLocationTracking()
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        notificationService.clearAndScheduleAllDefaultNotifications()

        initializeWindowIfNeeded()
        
        appLifecycleService.publish(.movedToForeground(withDailyVotingNotificationDate: dailyVotingNotificationDate))
        dailyVotingNotificationDate = nil
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings)
    {
        notificationAuthorizedSubject.on(.next(()))
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        coreDataStack.saveContext()
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification)
    {
        dailyVotingNotificationDate = dailyVotingDate(notification)
    }
    
    private func dailyVotingDate(_ notification: UILocalNotification) -> Date?
    {
        guard
            let type = notification.userInfo?["notificationType"] as? String,
            type == NotificationType.repeatWeekly.rawValue,
            let fireDate = notification.fireDate,
            fireDate.dayOfWeek != 6
        else { return nil }
        
        return fireDate
    }
    
    @available(iOS 10.0, *)
    fileprivate func dailyVotingDate(_ notification: UNNotification) -> Date?
    {
        guard
            let type = notification.request.content.userInfo["notificationType"] as? String,
            type == NotificationType.repeatWeekly.rawValue,
            notification.date.dayOfWeek != 6
        else { return nil }
        
        return notification.date
    }
}

@available(iOS 10.0, *)
extension AppDelegate:UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        
        dailyVotingNotificationDate = dailyVotingDate(response.notification)
        completionHandler()
    }
}
