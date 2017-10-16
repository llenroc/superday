import Foundation
import RxSwift

protocol SettingsService
{
    //MARK: Properties
    var installDate : Date? { get }
    
    var isFirstTimeAppRuns : Bool { get }
    
    var isPostCoreMotionUser : Bool { get }
    
    var lastLocation : Location? { get }
    
    var lastTimelineGenerationDate: Date? { get }
    
    var hasLocationPermission : Bool { get }
    
    var hasCoreMotionPermission : Bool { get }
    
    var hasNotificationPermission : Bool { get }
    var shouldAskForNotificationPermission : Bool { get }
    
    var userEverGaveLocationPermission : Bool { get }
    
    var userEverGaveMotionPermission : Bool { get }
    
    var didShowWelcomeMessage : Bool { get }
    
    var lastShownWeeklyRating : Date? { get }
    
    var motionPermissionGranted: Observable<Bool> { get }
    
    //MARK: Methods
    func setIsFirstTimeAppRuns()
    
    func setIsPostCoreMotionUser()
    
    func setInstallDate(_ date: Date)
    
    func setLastLocation(_ location: Location)
    
    func setLastTimelineGenerationDate(_ date: Date)
        
    func setUserGaveLocationPermission()
    
    func setCoreMotionPermission(userGavePermission: Bool)
    
    func setUserRejectedNotificationPermission()
    func setShouldAskForNotificationPermission()
    
    func setWelcomeMessageShown()
    
    func setVote(forDate date: Date)
    func lastSevenDaysOfVotingHistory() -> [Date]
    
    func setLastShownWeeklyRating(_ date: Date)
}
