import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    enum RootScreen {
        case rooms
        case savedEstimates
    }

    @Published var rootScreen: RootScreen = .rooms
    @Published var rootViewID = UUID()

    func show(_ screen: RootScreen, resetViewTree: Bool = false) {
        rootScreen = screen
        if resetViewTree {
            rootViewID = UUID()
        }
    }
}
