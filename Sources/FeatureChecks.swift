import Foundation
import AppKit
@MainActor enum FeatureChecks {
    static func run() async {
        var failed = 0
        func check(_ condition: Bool, _ name: String) { print((condition ? "PASS " : "FAIL ") + name); if !condition { failed += 1 } }
        check(ModuleMetadata.value["protocolVersion"] as? Int == 1, "module protocol metadata")
        check(!ModuleMetadata.id.contains("/"), "stable module identity")
        check(FileManager.default.fileExists(atPath: Bundle.main.resourcePath! + "/module.json"), "standalone manifest bundled")
        await SelfTests.run()
        check(BuildConfig.defaultLogin == "octocat", "public install uses neutral default account")
        print("MODULE_TESTS \(failed == 0 ? "OK" : "FAILED")")
        if failed > 0 { exit(1) }
    }
}
