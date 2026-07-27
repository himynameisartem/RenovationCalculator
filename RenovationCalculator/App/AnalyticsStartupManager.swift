import Foundation

enum AnalyticsStartupManager {
    private static var didStart = false

    static func start() {
        guard !didStart else { return }
        didStart = true

        Task { @MainActor in
            AppMetricaBridge.activateIfPossible()
        }
    }
}
