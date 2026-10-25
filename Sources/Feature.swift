import SwiftUI
import AppKit

@MainActor final class FeatureController: ObservableObject {
    let github = GroveStore()
    var content: AnyView { AnyView(GroveRootView(store: github)) }
    func start() { github.start() }
    func stop() {}
    func refresh() { Task { await github.refresh() } }
    func perform(_ action: String) async {}
    var summary: [String:String] { ["账户": github.login, "今日贡献": String(github.snapshot.today), "全年贡献": String(github.snapshot.total), "状态": github.error ?? "每 15 分钟同步"] }
}

extension FeatureController { var menuImage: NSImage? { nil } }

extension FeatureController { var previewContent: AnyView { AnyView(GroveRootView(store: github, exportMode: true)) } }
