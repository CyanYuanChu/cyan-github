import Foundation

enum BuildConfig {
    static var defaultLogin: String {
        Bundle.main.object(forInfoDictionaryKey: "GroveDefaultLogin") as? String ?? "octocat"
    }
}
