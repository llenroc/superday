import Foundation
import RxSwift
@testable import teferi

class MockMotionService: MotionService
{
    var motionAuthorizationGranted: Observable<Bool> {
        return Observable.empty()
    }
    
    func askForAuthorization()
    {
        
    }
    
    func getActivities(since start: Date, until end: Date) -> Observable<[MotionEvent]>
    {
        return Observable.empty()
    }
}
