import UIKit
import Foundation
import RxSwift
@testable import teferi

class MockLocator : ViewModelLocator
{
    var timeService = MockTimeService()
    var metricsService = MockMetricsService()
    var timeSlotService : MockTimeSlotService
    var feedbackService = MockFeedbackService()
    var settingsService = MockSettingsService()
    var locationService = MockLocationService()
    var editStateService = MockEditStateService()
    var smartGuessService = MockSmartGuessService()
    var selectedDateService = MockSelectedDateService()
    var appLifecycleService = MockAppLifecycleService()
    var loggingService = MockLoggingService()
    var notificationService  = MockNotificationService()
    var motionService = MockMotionService()
    var trackEventService = MockTrackEventService()
    
    init()
    {
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
    }

    func getNavigationViewModel(forViewController viewController: UIViewController) -> NavigationViewModel
    {
        let feedbackService = (self.feedbackService as! MailFeedbackService).with(viewController: viewController)
        
        return NavigationViewModel(timeService: timeService,
                                       feedbackService: feedbackService,
                                       selectedDateService: selectedDateService,
                                       appLifecycleService: appLifecycleService)
    }
    
    func getIntroViewModel() -> IntroViewModel
    {
        return IntroViewModel(settingsService: settingsService)
    }
    
    func getOnboardingViewModel() -> OnboardingViewModel
    {
        return OnboardingViewModel(timeService: timeService,
                                   timeSlotService: timeSlotService,
                                   settingsService: settingsService,
                                   appLifecycleService: appLifecycleService,
                                   motionService: motionService,
                                   locationService: locationService)
    }
    
    func getMainViewModel() -> MainViewModel
    {
        return MainViewModel(loggingService: loggingService,
                             timeService: timeService,
                             metricsService: metricsService,
                             timeSlotService: timeSlotService,
                             editStateService: editStateService,
                             smartGuessService: smartGuessService,
                             selectedDateService: selectedDateService,
                             settingsService: settingsService,
                             appLifecycleService: appLifecycleService,
                             locationService: locationService,
                             trackEventService: trackEventService,
                             motionService: motionService)
    }
    
    func getPagerViewModel() -> PagerViewModel
    {
        return PagerViewModel(timeService: timeService,
                              timeSlotService: timeSlotService,
                              settingsService: settingsService,
                              editStateService: editStateService,
                              appLifecycleService: appLifecycleService,
                              selectedDateService: selectedDateService)
    }
    
    func getTimelineViewModel(forDate date: Date) -> TimelineViewModel
    {
        return TimelineViewModel(date: date,
                                 timeService: timeService,
                                 timeSlotService: timeSlotService,
                                 editStateService: editStateService,
                                 appLifecycleService: appLifecycleService,
                                 loggingService: loggingService,
                                 settingsService: settingsService,
                                 metricsService: metricsService)
    }
    
    func getLocationPermissionViewModel() -> PermissionViewModel
    {
        let viewModel = LocationPermissionViewModel(timeService: timeService,
                                                    settingsService: settingsService,
                                                    appLifecycleService: appLifecycleService)
        
        return viewModel
    }
    
    func getMotionPermissionViewModel() -> PermissionViewModel
    {
        let viewModel = MotionPermissionViewModel(settingsService: settingsService,
                                                  appLifecycleService: appLifecycleService)
        
        return viewModel
    }
    
    func getNotificationPermissionViewModel() -> PermissionViewModel
    {
        return NotificationPermissionViewModel(notificationService: notificationService,
                                               settingsService: settingsService,
                                               appLifecycleService: appLifecycleService)
    }
    
    func getCMAccessForExistingUsersViewModel() -> CMAccessForExistingUsersViewModel
    {
        return CMAccessForExistingUsersViewModel(settingsService: settingsService, motionService: motionService)
    }
    
    func getCalendarViewModel() -> CalendarViewModel
    {
        return CalendarViewModel(timeService: timeService,
                                 settingsService: settingsService,
                                 timeSlotService: timeSlotService,
                                 selectedDateService: selectedDateService)
    }
    
    func getWeeklySummaryViewModel() -> WeeklySummaryViewModel
    {
        return WeeklySummaryViewModel(timeService: timeService,
                                      timeSlotService: timeSlotService,
                                      settingsService: settingsService)
    }
    
    func getDailySummaryViewModel(forDate date: Date) -> DailySummaryViewModel
    {
        return DailySummaryViewModel(date: date,
                                     timeService: timeService,
                                     timeSlotService: timeSlotService,
                                     appLifecycleService: appLifecycleService,
                                     loggingService: loggingService)
    }
    
    func getSummaryViewModel() -> SummaryViewModel
    {
        return SummaryViewModel(selectedDateService: selectedDateService)
    }
    
    func getSummaryPageViewModel(forDate date: Date) -> SummaryPageViewModel
    {
        return SummaryPageViewModel(date: date,
                                    timeService: timeService,
                                    settingsService: settingsService)
    }
    
    func getRatingViewModel(start startDate: Date, end endDate: Date) -> RatingViewModel
    {
        return RatingViewModel(startDate: startDate,
                               endDate: endDate,
                               timeSlotService: timeSlotService,
                               metricsService: metricsService,
                               settingsService: settingsService,
                               timeService: timeService)
    }
    
    func getEditTimeslotViewModel(for startDate: Date, timelineItemsObservable: Observable<[TimelineItem]>, isShowingSubSlot: Bool) -> EditTimeslotViewModel
    {
        return EditTimeslotViewModel(startDate: startDate,
                                     isShowingSubSlot: isShowingSubSlot,
                                     timelineItemsObservable: timelineItemsObservable,
                                     timeSlotService: timeSlotService,
                                     metricsService: metricsService,
                                     smartGuessService: smartGuessService,
                                     timeService: timeService)
    }
}
