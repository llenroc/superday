import CoreData
import UIKit
import CoreLocation
import RxSwift

class DefaultSettingsService : SettingsService
{
    //MARK: Public Properties
    
    var installDate : Date?
    {
        return get(forKey: installDateKey)
    }
    
    var isFirstTimeAppRuns : Bool
    {
        return !getBool(forKey: isFirstTimeAppRunsKey)
    }
    
    var isPostCoreMotionUser : Bool
    {
        return getBool(forKey: isPostCoreMotionUserKey)
    }
    
    var lastLocation : Location?
    {
        var location : Location? = nil
        
        let possibleTime = get(forKey: lastLocationDateKey) as Date?
        
        if let time = possibleTime
        {
            let latitude = getDouble(forKey: lastLocationLatKey)
            let longitude = getDouble(forKey: lastLocationLngKey)
            let horizontalAccuracy = get(forKey: lastLocationHorizontalAccuracyKey) as Double? ?? 0.0
            
            location = Location(timestamp: time,
                                latitude: latitude, longitude: longitude,
                                accuracy: horizontalAccuracy)
        }
        
        return location
    }
    
    var lastTimelineGenerationDate: Date?
    {
        return get(forKey: lastTimelineGenerationDateKey)
    }
    
    var hasLocationPermission : Bool
    {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    var hasCoreMotionPermission : Bool
    {
        return getBool(forKey: hasCoreMotionPermissionKey)
    }
    
    var hasNotificationPermission : Bool
    {
        guard !getBool(forKey: userRejectedNotificationPermissionKey) else { return true }
        let notificationSettings = UIApplication.shared.currentUserNotificationSettings
        return notificationSettings?.types.contains([.alert, .badge]) ?? false
    }
    
    var shouldAskForNotificationPermission : Bool
    {
        return getBool(forKey: shouldAskForNotificationPermissionKey)
    }
    
    var userEverGaveLocationPermission: Bool
    {
        return getBool(forKey: userGaveLocationPermissionKey)
    }
    
    var userEverGaveMotionPermission: Bool
    {
        return getBool(forKey: userGaveMotionPermissionKey)
    }
    
    var didShowWelcomeMessage : Bool
    {
        return getBool(forKey: welcomeMessageShownKey)
    }
    
    var lastShownWeeklyRating : Date?
    {
        return get(forKey: lastShownWeeklyRatingKey)
    }
    
    var motionPermissionGranted: Observable<Bool>
    {
        return UserDefaults.standard.rx.observe(Bool.self, hasCoreMotionPermissionKey)
            .filterNil()
    }
    
    //MARK: Private Properties
    
    private let timeService : TimeService
    
    private let installDateKey = "installDate"
    private let lastLocationLatKey = "lastLocationLat"
    private let lastLocationLngKey = "lastLocationLng"
    private let lastLocationDateKey = "lastLocationDate"
    private let lastLocationHorizontalAccuracyKey = "lastLocationHorizongalAccuracy"
    private let userGaveLocationPermissionKey = "canIgnoreLocationPermission"
    private let userGaveMotionPermissionKey = "userGaveMotionPermissionKey"
    private let userRejectedNotificationPermissionKey = "userRejectedNotificationPermission"
    private let welcomeMessageShownKey = "welcomeMessageShown"
    private let votingHistoryKey = "votingHistory"
    private let lastShownWeeklyRatingKey = "lastShownWeeklyRating"
    private let isFirstTimeAppRunsKey = "isFirstTimeAppRuns"
    private let isPostCoreMotionUserKey = "isPostCoreMotionUser"
    private let hasCoreMotionPermissionKey = "hasCoreMotionPermission"
    private let lastTimelineGenerationDateKey = "lastTimelineGenerationDate"
    private let shouldAskForNotificationPermissionKey = "shouldAskForNotificationPermission"
    
    //MARK: Initialiazers
    init (timeService : TimeService)
    {
        self.timeService = timeService
    }

    //MARK: Public Methods
    func setIsFirstTimeAppRuns()
    {
        set(true, forKey: isFirstTimeAppRunsKey)
    }
    
    func setIsPostCoreMotionUser()
    {
        set(true, forKey: isPostCoreMotionUserKey)
    }
    
    func setInstallDate(_ date: Date)
    {
        guard installDate == nil else { return }
        
        set(date, forKey: installDateKey)
    }
    
    func setLastLocation(_ location: Location)
    {
        set(location.timestamp, forKey: lastLocationDateKey)
        set(location.latitude, forKey: lastLocationLatKey)
        set(location.longitude, forKey: lastLocationLngKey)
        set(location.horizontalAccuracy, forKey: lastLocationHorizontalAccuracyKey)
    }
    
    func setLastTimelineGenerationDate(_ date: Date)
    {
        set(date, forKey: lastTimelineGenerationDateKey)
    }
    
    func setUserGaveLocationPermission()
    {
        set(true, forKey: userGaveLocationPermissionKey)
    }
    
    func setCoreMotionPermission(userGavePermission: Bool)
    {
        set(true, forKey: userGaveMotionPermissionKey)
        set(userGavePermission, forKey: hasCoreMotionPermissionKey)
    }
    
    func setUserRejectedNotificationPermission()
    {
        set(true, forKey: userRejectedNotificationPermissionKey)
    }
    
    func setShouldAskForNotificationPermission()
    {
        set(true, forKey: shouldAskForNotificationPermissionKey)
    }
    
    func setWelcomeMessageShown()
    {
        set(true, forKey: welcomeMessageShownKey)
    }
    
    func setVote(forDate date: Date)
    {
        var history = lastSevenDaysOfVotingHistory()
        history.append(date.ignoreTimeComponents())
        UserDefaults.standard.setValue(history, forKey: votingHistoryKey)
    }
    
    func lastSevenDaysOfVotingHistory() -> [Date]
    {
        guard let history = UserDefaults.standard.object(forKey: votingHistoryKey) as? [Date]
        else
        {
            let history = [Date]()
            UserDefaults.standard.setValue(history, forKey: votingHistoryKey)
            return history
        }
        
        let cleanedUpHistory = history.filter { timeService.now.timeIntervalSince($0) < Constants.sevenDaysInSeconds }
        
        UserDefaults.standard.setValue(cleanedUpHistory, forKey: votingHistoryKey)
        
        return cleanedUpHistory
    }
    
    func setLastShownWeeklyRating(_ date: Date)
    {
        set(date, forKey: lastShownWeeklyRatingKey)
    }
    
    // MARK: Private Methods
    private func get<T>(forKey key: String) -> T?
    {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    private func getDouble(forKey key: String) -> Double
    {
        return UserDefaults.standard.double(forKey: key)
    }
    private func getBool(forKey key: String) -> Bool
    {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func set(_ value: Date?, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func set(_ value: Double, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func set(_ value: Bool, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    
}
