import UIKit

class NavigationPresenter : NSObject
{
    private weak var viewController : NavigationController!
    private let viewModelLocator : ViewModelLocator
    
    private var calendarViewController : CalendarViewController? = nil

    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> NavigationController
    {
        let presenter = NavigationPresenter(viewModelLocator: viewModelLocator)
        
        let mainViewController = MainPresenter.create(with: viewModelLocator)
        let viewController = NavigationController(rootViewController: mainViewController)
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getNavigationViewModel(forViewController: viewController))
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func toggleCalendar()
    {
        if let _ = calendarViewController {
            hideCalendar()
        } else {
            showCalendar()
        }
    }
    
    func showWeeklySummary()
    {
        let vc = WeeklySummaryPresenter.create(with: viewModelLocator)
        viewController.present(vc, animated: true, completion: nil)
    }
    
    private func showCalendar()
    {
        calendarViewController = CalendarPresenter.create(with: viewModelLocator, dismissCallback: didHideCalendar)
        viewController.topViewController?.addChildViewController(calendarViewController!)        
        viewController.topViewController?.view.addSubview(calendarViewController!.view)
        calendarViewController!.didMove(toParentViewController: viewController.topViewController)
    }
    
    private func hideCalendar()
    {
        calendarViewController?.hide()
    }
    
    private func didHideCalendar()
    {
        guard let calendar = calendarViewController else { return }
        
        calendar.willMove(toParentViewController: nil)
        calendar.view.removeFromSuperview()
        calendar.removeFromParentViewController()
        
        calendarViewController = nil
    }
}
