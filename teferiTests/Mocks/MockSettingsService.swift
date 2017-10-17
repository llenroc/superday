import Foundation
import RxSwift
@testable import teferi

class MockSettingsService : SettingsService
{
    //MARK: Properties
    var nextSmartGuessId = 0
    var installDate : Date? = Date()
    var lastInactiveDate : Date? = nil
    var lastLocation : Location? = nil
    var lastTimelineGenerationDate: Date? = nil
    var userEverGaveLocationPermission : Bool = false
    var userEverGaveMotionPermission: Bool = false
    var didShowWelcomeMessage : Bool = true
    var lastShownWeeklyRating : Date? = Date()

    var motionPermissionGranted: Observable<Bool> = Observable<Bool>.empty()
    
    var hasLocationPermission = true
    var hasNotificationPermission = true
    var shouldAskForNotificationPermission = false
    var hasCoreMotionPermission = true
    var isFirstTimeAppRuns = false
    var isPostCoreMotionUser = true
        
    //MARK: Methods
    func setIsFirstTimeAppRuns()
    {
        isFirstTimeAppRuns = false
    }
    
    func setIsPostCoreMotionUser()
    {
        isPostCoreMotionUser = true
    }
        
    //MARK: Methods
    func setInstallDate(_ date: Date)
    {
        installDate = date
    }
    
    func setLastLocation(_ location: Location)
    {
        lastLocation = location
    }
    
    func setLastTimelineGenerationDate(_ date: Date)
    {
        lastTimelineGenerationDate = date
    }
    
    func getNextSmartGuessId() -> Int
    {
        return nextSmartGuessId
    }
    
    func incrementSmartGuessId()
    {
        nextSmartGuessId += 1
    }
    
    func setUserGaveLocationPermission()
    {
        userEverGaveLocationPermission = true
    }
    
    func setCoreMotionPermission(userGavePermission: Bool)
    {
        hasCoreMotionPermission = userGavePermission
    }
    
    func setUserRejectedNotificationPermission()
    {
        hasNotificationPermission = true
    }
    
    func setShouldAskForNotificationPermission()
    {
        shouldAskForNotificationPermission = true
    }
    
    func setWelcomeMessageShown()
    {
        didShowWelcomeMessage = true
    }
    
    func setVote(forDate date: Date)
    {
        
    }
    
    func lastSevenDaysOfVotingHistory() -> [Date]
    {
        return []
    }
    
    func setLastShownWeeklyRating(_ date: Date)
    {
        lastShownWeeklyRating = date
    }
}
