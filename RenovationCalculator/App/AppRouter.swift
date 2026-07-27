import Foundation
import Combine
import SwiftUI
//
@MainActor
final class AppRouter: ObservableObject {
    enum RootScreen {
        case home
        case rooms
        case savedEstimates
    }

    @Published var rootScreen: RootScreen = .home
    @Published var rootViewID = UUID()

    func show(_ screen: RootScreen, resetViewTree: Bool = false) {
        rootScreen = screen
        if resetViewTree {
            rootViewID = UUID()
        }
    }

    func handleIncomingURL(_ url: URL) {
        // Expected examples:
        // renovation://home
        // https://<domain>/home
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()

        if host == "home" || path == "/home" || path == "/" {
            show(.home, resetViewTree: true)
            return
        }

        if host == "calculator" || path == "/calculator" || path == "/rooms" {
            show(.rooms, resetViewTree: true)
            return
        }

        if host == "estimates" || path == "/estimates" {
            show(.savedEstimates, resetViewTree: true)
        }
    }
}

