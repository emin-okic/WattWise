import Foundation

final class AppLifecycleHooks {
    private var dayChangeObserver: NSObjectProtocol?

    func startObservingDayChange(onChange: @escaping () -> Void) {
        dayChangeObserver = NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { _ in
            onChange()
        }
    }

    deinit {
        if let obs = dayChangeObserver { NotificationCenter.default.removeObserver(obs) }
    }
}
