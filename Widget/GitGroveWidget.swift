import SwiftUI
import WidgetKit
import AppIntents

enum NativeWidgetTheme: String, AppEnum {
    case system, light, dark
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "主题"
    static var caseDisplayRepresentations: [NativeWidgetTheme: DisplayRepresentation] = [.system: "跟随系统", .light: "暖白", .dark: "墨绿"]
}

struct GroveConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Cyan GitHub 账户"
    static var description: IntentDescription = "选择 GitHub 账户和外观。"
    @Parameter(title: "GitHub 用户名", default: "octocat") var username: String
    @Parameter(title: "主题", default: .system) var theme: NativeWidgetTheme
}

struct GroveEntry: TimelineEntry {
    var date: Date
    var snapshot: GroveSnapshot
    var theme: NativeWidgetTheme
    var preview = false
    var error: String? = nil
}

struct GroveProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GroveEntry {
        GroveEntry(date: .now, snapshot: .demo(), theme: .system, preview: true)
    }
    func snapshot(for configuration: GroveConfiguration, in context: Context) async -> GroveEntry {
        if context.isPreview { return GroveEntry(date: .now, snapshot: .demo(), theme: configuration.theme, preview: true) }
        return await load(configuration)
    }
    func timeline(for configuration: GroveConfiguration, in context: Context) async -> Timeline<GroveEntry> {
        let entry = await load(configuration)
        // 这是建议刷新时间，实际运行由 WidgetKit 决定。
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(1800)))
    }
    func load(_ configuration: GroveConfiguration) async -> GroveEntry {
        let login = configuration.username.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let clean = try GitHubClient.validate(login)
            var request = URLRequest(url: URL(string: "https://github.com/users/\(clean)/contributions")!)
            request.timeoutInterval = 20
            request.setValue("GitGrove/0.2", forHTTPHeaderField: "User-Agent")
            request.setValue("en-US", forHTTPHeaderField: "Accept-Language")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200, let html = String(data: data, encoding: .utf8) else { throw GroveError.message("暂时无法连接 GitHub") }
            let days = try PublicCalendar.parse(html)
            var result = GroveSnapshot.empty
            result.login = clean; result.name = clean; result.days = days
            result.total = days.reduce(0) { $0 + $1.count }; result.updatedAt = .now
            if let data = try? JSONEncoder().encode(result) { UserDefaults.standard.set(data, forKey: cacheKey(clean)) }
            return GroveEntry(date: .now, snapshot: result, theme: configuration.theme)
        } catch {
            let cached = cached(login)
            var result = cached ?? .empty; result.login = login
            return GroveEntry(date: .now, snapshot: result, theme: configuration.theme, error: cached == nil ? "右键检查用户名，或稍后等待同步。" : "离线，显示上次同步结果")
        }
    }
    func cacheKey(_ login: String) -> String { "public-calendar.\(login.lowercased())" }
    func cached(_ login: String) -> GroveSnapshot? {
        guard (try? GitHubClient.validate(login)) != nil, let data = UserDefaults.standard.data(forKey: cacheKey(login)) else { return nil }
        return try? JSONDecoder().decode(GroveSnapshot.self, from: data)
    }
}

struct GroveWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    var entry: GroveEntry
    var dark: Bool { entry.theme == .dark || (entry.theme == .system && colorScheme == .dark) }
    var body: some View {
        NativeContributionView(snapshot: entry.snapshot, family: family, dark: dark, preview: entry.preview, error: entry.error)
    }
}

@main struct GitGroveWidget: Widget {
    let kind = "GitGroveNativeContributions"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GroveConfiguration.self, provider: GroveProvider()) { GroveWidgetEntryView(entry: $0) }
            .configurationDisplayName("Cyan GitHub · 贡献日历")
            .description("每天的一点进展。查看 GitHub 公开贡献与连续贡献天数。")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // 保留系统边距、背景与形状处理。没有自定义桌面窗口或拖放逻辑。
    }
}
