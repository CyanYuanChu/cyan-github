import Foundation
import AppKit

@MainActor enum WidgetSupport {
    static func prepare() async throws {
        guard Bundle.main.bundleIdentifier != ModuleMetadata.value["bundleID"] as? String,
              !CommandLine.arguments.contains("--no-widget-registration") else { return }
        let source=FeatureResources.bundle.bundleURL.appendingPathComponent("Contents/Resources/WidgetSupport/Cyan Grove GitHub Widgets.app")
        guard FileManager.default.fileExists(atPath:source.path) else{return}
        let apps=FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications",isDirectory:true)
        let target=apps.appendingPathComponent("Cyan Grove GitHub Widgets.app",isDirectory:true)
        let version=ModuleMetadata.value["version"] as! String
        let marker="Contents/Resources/feature-version.txt"
        if (try? String(contentsOf:target.appendingPathComponent(marker),encoding:.utf8)) == version {return}
        try FileManager.default.createDirectory(at:apps,withIntermediateDirectories:true)
        if FileManager.default.fileExists(atPath:target.path){
            guard Bundle(url:target)?.bundleIdentifier=="io.github.cyanyuanchu.cyangrove.github-widgets" else{throw GroveError.message("桌面组件支持位置已有其他软件，没有覆盖。")}
            var trashed:NSURL?;try FileManager.default.trashItem(at:target,resultingItemURL:&trashed)
        }
        try FileManager.default.copyItem(at:source,to:target)
        let config=NSWorkspace.OpenConfiguration();config.activates=false
        _ = try await NSWorkspace.shared.openApplication(at:target,configuration:config)
    }
}
