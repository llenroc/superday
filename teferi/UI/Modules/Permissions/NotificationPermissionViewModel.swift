import RxSwift
import Foundation

class NotificationPermissionViewModel : PermissionViewModel
{
    // MARK: Public Properties
    var isSecondaryButtonHidden : Bool
    {
        return false
    }
    
    var titleText : String?
    {
        return L10n.notificationsPermissionsTitle
    }
    
    var descriptionText : String
    {
        return L10n.notificationsPermissionsDescription
    }
    
    var enableButtonTitle : String
    {
        return L10n.notificationsPermissionsEnableButtonTitle
    }
    
    var secondaryButtonTitle : String?
    {
        return L10n.notificationsPermissionsSecondaryButtonTitle
    }
    
    var image : UIImage?
    {
        return nil
    }
    
    var permissionGivenObservable : Observable<Void>
    {
        return self.appLifecycleService
            .movedToForegroundObservable
            .map { [unowned self] in
                return self.settingsService.hasNotificationPermission
            }
            .filter{ $0 }
            .mapTo(())
    }
    
    private(set) lazy var hideOverlayObservable : Observable<Void> =
    {
        return self.appLifecycleService.movedToForegroundObservable
            .map(self.overlayVisibilityState)
            .filter{ !$0 }
            .mapTo(())
    }()
    
    // MARK: Private Properties
    private let notificationService : NotificationService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    
    private let disposeBag = DisposeBag()
    
    // MARK: Initializers
    init(notificationService: NotificationService,
         settingsService: SettingsService,
         appLifecycleService : AppLifecycleService)
    {
        self.notificationService = notificationService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
    }
    
    // MARK: Public Methods
    
    func getUserPermission()
    {
        notificationService.requestNotificationPermission(completed: {})
    }
    
    func permissionGiven() {}
    
    func secondaryAction()
    {
        settingsService.setUserRejectedNotificationPermission()
    }
    
    // MARK: Private Methods
    
    private func overlayVisibilityState() -> Bool
    {
        return !settingsService.hasNotificationPermission
    }
}

