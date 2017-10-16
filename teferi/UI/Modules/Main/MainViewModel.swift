import Foundation
import RxSwift

///ViewModel for the MainViewController.
class MainViewModel : RxViewModel
{
    // MARK: Public Properties
    let dateObservable : Observable<Date>
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, TimelineItem)>
    let categoryProvider : CategoryProvider
    
    var currentDate : Date { return self.timeService.now }
    
    var showPermissionControllerObservable : Observable<PermissionRequestType>
    {
        return Observable.of(
            self.appLifecycleService.movedToForegroundObservable,
            self.didBecomeActive,
            self.motionService.motionAuthorizationGranted.mapTo(()))
            .merge()
            .map { [unowned self] () -> PermissionRequestType? in
                if self.shouldShowLocationPermissionRequest() {
                    return PermissionRequestType.location
                } else if self.shouldShowMotionPermissionRequest() {
                    return PermissionRequestType.motion
                } else if self.shouldShowNotificationPermissionRequest() {
                    return PermissionRequestType.notification
                }
                return nil
            }
            .filterNil()
    }
    
    var welcomeMessageHiddenObservable : Observable<Bool>
    {
        if self.settingsService.didShowWelcomeMessage {
            return Observable.just(true)
        }
        
        return Observable.of(
            self.didBecomeActive.skip(1),
            self.beganEditingObservable.mapTo(()),
            self.timeSlotService.timeSlotCreatedObservable.mapTo(()).skip(1))
            .merge()
            .mapTo(true)
            .startWith(false)
            .do(onNext: { _ in
                self.settingsService.setWelcomeMessageShown()
            })
    }
    
    var moveToForegroundObservable : Observable<Void>
    {
        return appLifecycleService.movedToForegroundObservable
    }
    
    var shouldShowCMAccessForExistingUsers : Bool
    {
        return !settingsService.isPostCoreMotionUser && !settingsService.hasCoreMotionPermission
    }
    
    var shouldShowWeeklyRatingUI : Bool
    {
        guard let installDate = settingsService.installDate else { return false }
        
        if
            let lastShown = settingsService.lastShownWeeklyRating,
            lastShown.ignoreTimeComponents() == timeService.now.ignoreTimeComponents() || lastShown.ignoreTimeComponents() == timeService.now.add(days: -1).ignoreTimeComponents()
        {
            return false
        }
        
        let itIsSevenOrMoreDaysSinceTheAppInstall = timeService.now.timeIntervalSince(installDate) >= Constants.sevenDaysInSeconds
        let itIsSundayAfterWeeklyRatingHour = (timeService.now.dayOfWeek == 0 ? timeService.now.hour >= Constants.hourToShowWeeklyRatingUI : false)
        let itIsMondayBeforeWeeklyRatingHour = (timeService.now.dayOfWeek == 1 ? timeService.now.hour < Constants.hourToShowWeeklyRatingUI : false)
        let itIsInTheRangeBetweenSundayAfterWeeklyRatingHourAndModayBeforeWeeklyRatingHour = itIsSundayAfterWeeklyRatingHour || itIsMondayBeforeWeeklyRatingHour
        
        let shouldShowRatingUI = itIsSevenOrMoreDaysSinceTheAppInstall && itIsInTheRangeBetweenSundayAfterWeeklyRatingHourAndModayBeforeWeeklyRatingHour
        
        return shouldShowRatingUI
    }
    
    var weeklyRatingStartDate : Date
    {
        return timeService.now.add(days: -6)
    }
    
    var weeklyRatingEndDate : Date
    {
        return timeService.now
    }

    var locating:Observable<Bool> {
        return locatingActivity.asObservable()
            .observeOn(MainScheduler.instance)
    }
    
    var generating: Observable<Bool> {
        return generatingTimelineActivity.asObservable()
            .observeOn(MainScheduler.instance)
    }
    
    // MARK: Private Properties
    private let loggingService: LoggingService
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    private let locationService: LocationService
    private let trackEventService: TrackEventService
    private let motionService: MotionService
    
    private let locatingActivity = ActivityIndicator()
    private let generatingTimelineActivity = ActivityIndicator()
    private let timelineGenerator: TimelineGenerator
    private var disposeBag = DisposeBag()
    
    // MARK: Initializer
    init(loggingService: LoggingService,
         timeService: TimeService,
         metricsService: MetricsService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         smartGuessService : SmartGuessService,
         selectedDateService : SelectedDateService,
         settingsService : SettingsService,
         appLifecycleService: AppLifecycleService,
         locationService: LocationService,
         trackEventService: TrackEventService,
         motionService: MotionService)
    {
        self.loggingService = loggingService
        self.timeService = timeService
        self.metricsService = metricsService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.smartGuessService = smartGuessService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
        self.locationService = locationService
        self.trackEventService = trackEventService
        self.motionService = motionService
        
        timelineGenerator = TimelineGenerator(loggingService: loggingService,
                                              trackEventService: trackEventService,
                                              smartGuessService: smartGuessService,
                                              timeService: timeService,
                                              timeSlotService: timeSlotService,
                                              metricsService: metricsService,
                                              settingsService: settingsService,
                                              motionService: motionService)
        
        isEditingObservable = editStateService.isEditingObservable
        dateObservable = selectedDateService.currentlySelectedDateObservable
        beganEditingObservable = editStateService.beganEditingObservable
        
        categoryProvider = DefaultCategoryProvider(timeSlotService: timeSlotService)

        super.init()
        
        appLifecycleService.movedToForegroundObservable
            .flatMap { [unowned self] _ -> Observable<Location> in
                if let location = settingsService.lastLocation {
                    return Observable.just(location)
                }
                
                return locationService.currentLocation
                    .subscribeOn(OperationQueueScheduler(operationQueue: OperationQueue()))
                    .do(onNext: settingsService.setLastLocation)
                    .trackActivity(self.locatingActivity)
            }
            .flatMap { [unowned self] _ in
                return self.timelineGenerator.execute()
                    .trackActivity(self.generatingTimelineActivity)
            }
            .subscribe()
            .addDisposableTo(disposeBag)        

    }
    
    //MARK: Public Methods
    func notifyEditingEnded() { editStateService.notifyEditingEnded() }

    func addNewSlot(withCategory category: Category)
    {
        guard let timeSlot =
            timeSlotService.addTimeSlot(withStartTime: timeService.now,
                                             category: category,
                                             categoryWasSetByUser: true,
                                             tryUsingLatestLocation: true)
            else { return }
        
        if let location = timeSlot.location
        {
            smartGuessService.add(withCategory: timeSlot.category, location: location)
        }
        
        metricsService.log(event: .timeSlotManualCreation(date: timeService.now, category: category))
        metricsService.log(event: .timeSlotCreated(date: timeService.now, category: category, duration: nil))
    }
    
    //MARK: Private Methods
    
    private func shouldShowLocationPermissionRequest() -> Bool
    {
        return !settingsService.hasLocationPermission
    }
    
    private func shouldShowMotionPermissionRequest() -> Bool
    {
        return !settingsService.hasCoreMotionPermission
    }
    
    private func shouldShowNotificationPermissionRequest() -> Bool
    {
        return
            settingsService.shouldAskForNotificationPermission &&
            timeService.now.timeIntervalSince(settingsService.installDate!) >= 24 * 60 * 60 &&
            !settingsService.hasNotificationPermission
    }
}
