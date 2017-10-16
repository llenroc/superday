import RxSwift
import Foundation

protocol PermissionViewModel
{
    var hideOverlayObservable : Observable<Void> { get }
    var permissionGivenObservable : Observable<Void> { get }
    var isSecondaryButtonHidden : Bool { get }
    var titleText : String? { get }
    var descriptionText : String { get }
    var enableButtonTitle : String { get }
    var secondaryButtonTitle : String? { get }
    var image : UIImage? { get }
    
    func getUserPermission()
    func permissionGiven()
    func secondaryAction()
}
