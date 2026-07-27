import Foundation
import AppMetricaCore

enum AppMetricaBridge {
    static func activateIfPossible() {
        let key = Bundle.main.object(forInfoDictionaryKey: "APPMETRICA_API_KEY") as? String
        guard let key, !key.isEmpty else {
            print("[AppMetrica] API key is missing. Set APPMETRICA_API_KEY in Info.plist")
            return
        }

        guard let configuration = AppMetricaConfiguration(apiKey: key) else {
            print("[AppMetrica] Failed to create configuration")
            return
        }

        AppMetrica.activate(with: configuration)
        print("[AppMetrica] Activated")
    }

    static func reportOpen(url: URL) {
        AppMetrica.trackOpeningURL(url)
        AppMetrica.reportEvent(
            name: "deeplink_open",
            parameters: ["url": url.absoluteString],
            onFailure: nil
        )
    }
}
