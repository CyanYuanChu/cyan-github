import SwiftUI
import WidgetKit

@MainActor final class GroveStore: ObservableObject {
    @Published var snapshot = GroveSnapshot.empty
    @Published var loading = false
    @Published var error: String?
    @Published var notice: String?
    @Published var selected = "overview"
    let startup = StartupManager()
    @Published var login: String { didSet { FeaturePreferences.shared.set(login, forKey: "login") } }
    @Published var dark: Bool { didSet { FeaturePreferences.shared.set(dark, forKey: "dark") } }
    @Published var demo = false
    var palette: GrovePalette { GrovePalette(dark: dark) }
    var timer: Timer?
    private var generation = 0
    init() {
        let defaults = FeaturePreferences.shared
        login = defaults.string(forKey: "login") ?? BuildConfig.defaultLogin
        dark = defaults.bool(forKey: "dark")
        if let cached = GroveCache.load(login) { snapshot = cached }
    }
    func stop() { timer?.invalidate(); timer = nil; generation += 1; loading = false }
    func start() {
        guard timer == nil else { return }
        
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in Task { @MainActor in await self?.refresh() } }
    }
    func refresh() async {
        guard !loading && !demo else { return }
        loading = true; error = nil; notice = nil
        let requestLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = generation
        defer { if version == generation { loading = false } }
        do {
            let result = try await GitHubClient.fetch(login: requestLogin)
            guard version == generation, !demo, requestLogin == login.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            snapshot = result
            do { try GroveCache.save(result) } catch { notice = "已更新，离线缓存暂时无法写入。" }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            guard version == generation, !demo else { return }
            self.error = error.localizedDescription
        }
    }
    func connect(_ username: String) {
        do {
            let clean = try GitHubClient.validate(username)
            generation += 1; loading = false; demo = false; login = clean
            snapshot = GroveCache.load(clean) ?? .empty
            Task { await refresh() }
        } catch { self.error = error.localizedDescription }
    }
    func setDemo(_ enabled: Bool) {
        generation += 1; loading = false; error = nil; notice = nil; demo = enabled
        if enabled { snapshot = .demo() } else { snapshot = GroveCache.load(login) ?? .empty; Task { await refresh() } }
    }
    func open(_ url: String) {
        guard let parsed = URL(string: url), parsed.scheme == "https", parsed.host == "github.com" else { return }
        NSWorkspace.shared.open(parsed)
    }
}
