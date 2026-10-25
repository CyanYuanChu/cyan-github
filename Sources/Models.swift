import Foundation

struct ContributionDay: Codable, Identifiable, Hashable {
    var date: String
    var count: Int
    var level: Int
    var id: String { date }
}

struct CommitItem: Codable, Identifiable {
    var sha: String
    var message: String
    var repository: String
    var date: Date
    var url: String
    var id: String { repository + sha }
}

struct RepoItem: Codable, Identifiable {
    var name: String
    var url: String
    var language: String
    var color: String
    var count: Int
    var id: String { name }
}

struct GroveSnapshot: Codable {
    var login: String
    var name: String
    var avatar: String
    var days: [ContributionDay]
    var commits: [CommitItem]
    var repos: [RepoItem]
    var total: Int
    var publicRepos: Int
    var pullRequests: Int
    var issues: Int
    var updatedAt: Date
    var activityError: String?
    var isDemo: Bool = false

    static let empty = GroveSnapshot(login: "", name: "", avatar: "", days: [], commits: [], repos: [], total: 0, publicRepos: 0, pullRequests: 0, issues: 0, updatedAt: .distantPast)

    func todayKey(now: Date = .now) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.calendar = Calendar(identifier: .gregorian); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: now)
    }
    var today: Int { days.first { $0.date == todayKey() }?.count ?? 0 }
    var activeDays: Int { days.filter { $0.count > 0 }.count }
    var bestDay: Int { days.map(\.count).max() ?? 0 }
    var currentStreak: Int { streak(now: .now) }
    func streak(now: Date) -> Int {
        let valid = days.filter { $0.date <= todayKey(now: now) }.sorted { $0.date < $1.date }
        guard !valid.isEmpty else { return 0 }
        let counts = Dictionary(valid.map { ($0.date, $0.count) }, uniquingKeysWith: { _, b in b })
        var cursor = Calendar.current.startOfDay(for: now)
        // 今天尚未贡献时，昨日仍在延续的 streak 不会提前归零。
        if (counts[todayKey(now: cursor)] ?? 0) == 0 { cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)! }
        var result = 0
        while (counts[todayKey(now: cursor)] ?? 0) > 0 {
            result += 1; cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)!
        }
        return result
    }
    var longestStreak: Int {
        var best = 0, run = 0
        for day in days.sorted(by: { $0.date < $1.date }) { run = day.count > 0 ? run + 1 : 0; best = max(best, run) }
        return best
    }
    var lastSeven: Int {
        let cutoff = todayKey(now: Calendar.current.date(byAdding: .day, value: -6, to: .now)!)
        return days.filter { $0.date >= cutoff && $0.date <= todayKey() }.reduce(0) { $0 + $1.count }
    }
    var weeks: [[ContributionDay]] {
        guard let first = days.first else { return [] }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        let firstDate = f.date(from: first.date) ?? .now
        let offset = Calendar(identifier: .gregorian).component(.weekday, from: firstDate) - 1
        var padded = (0..<offset).map { ContributionDay(date: "pad-\($0)", count: -1, level: -1) } + days
        while padded.count % 7 != 0 { padded.append(ContributionDay(date: "pad-\(padded.count)", count: -1, level: -1)) }
        return stride(from: 0, to: padded.count, by: 7).map { Array(padded[$0..<min($0 + 7, padded.count)]) }
    }
    static func demo() -> GroveSnapshot {
        let cal = Calendar(identifier: .gregorian)
        let end = Date()
        let start = cal.date(byAdding: .day, value: -364, to: end)!
        let seed = GroveSnapshot.empty
        let days = (0..<365).map { index -> ContributionDay in
            let d = cal.date(byAdding: .day, value: index, to: start)!
            let n = (index * 37 + index * index * 13) % 29
            let weekend = cal.isDateInWeekend(d)
            let count = n < (weekend ? 18 : 6) ? 0 : (n % 12) + 1
            return ContributionDay(date: seed.todayKey(now: d), count: count, level: count == 0 ? 0 : min(4, 1 + count / 3))
        }
        return GroveSnapshot(login: "octocat", name: "The Octocat", avatar: "", days: days,
            commits: [CommitItem(sha: "a17e6c2", message: "Polish contribution calendar and empty states", repository: "octocat / git-grove", date: .now.addingTimeInterval(-1800), url: "https://github.com/octocat"), CommitItem(sha: "4f9b820", message: "Add a little more breathing room", repository: "octocat / design-system", date: .now.addingTimeInterval(-7200), url: "https://github.com/octocat"), CommitItem(sha: "b3c82d1", message: "Ship desktop widgets in three sizes", repository: "octocat / git-grove", date: .now.addingTimeInterval(-86000), url: "https://github.com/octocat")],
            repos: [RepoItem(name: "octocat/git-grove", url: "https://github.com/octocat", language: "Swift", color: "#F05138", count: 126), RepoItem(name: "octocat/design-system", url: "https://github.com/octocat", language: "TypeScript", color: "#3178C6", count: 82)], total: days.reduce(0) { $0 + $1.count }, publicRepos: 12, pullRequests: 3, issues: 2, updatedAt: .now, isDemo: true)
    }
}

enum GroveError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

enum GitHubClient {
    static func validate(_ login: String) throws -> String {
        let login = login.trimmingCharacters(in: .whitespacesAndNewlines)
        guard login.range(of: "^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$", options: .regularExpression) != nil else { throw GroveError.message("请输入有效的 GitHub 用户名（不是邮箱或链接）。") }
        return login
    }
    static let query = """
    query($login:String!){user(login:$login){login name avatarUrl repositories(ownerAffiliations:OWNER,privacy:PUBLIC){totalCount} pullRequests(states:OPEN){totalCount} issues(states:OPEN){totalCount} contributionsCollection{contributionCalendar{totalContributions weeks{contributionDays{date contributionCount contributionLevel}}} commitContributionsByRepository(maxRepositories:4){repository{nameWithOwner url primaryLanguage{name color}} contributions{totalCount}}}}}
    """
    static func process(_ arguments: [String]) throws -> Data {
        let executable = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh"].first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let executable else { throw GroveError.message("未找到 GitHub CLI。请先安装 gh 并运行 gh auth login。") }
        let task = Process(); task.executableURL = URL(fileURLWithPath: executable); task.arguments = arguments
        let out = Pipe(); task.standardOutput = out; task.standardError = FileHandle.nullDevice
        // 不读取或保存令牌；认证交给已登录的 gh。
        try task.run()
        let timeout = DispatchWorkItem { if task.isRunning { task.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 25, execute: timeout)
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit(); timeout.cancel()
        guard task.terminationStatus == 0 else { throw GroveError.message("GitHub 请求失败。请检查网络和 gh auth status，稍后重试。") }
        return data
    }
    static func fetch(login: String) async throws -> GroveSnapshot {
        let clean = try validate(login)
        return try await Task.detached(priority: .utility) {
            let data = try process(["api", "graphql", "-f", "query=\(query)", "-f", "login=\(clean)"])
            var snapshot = try parseGraph(data)
            do {
                let search = "search/commits?q=author:\(clean)&sort=author-date&order=desc&per_page=12"
                snapshot.commits = try parseCommits(process(["api", search, "-H", "Accept: application/vnd.github+json"]))
            } catch { snapshot.activityError = "最近提交暂时无法获取，下次刷新将重试。" }
            return snapshot
        }.value
    }
    static func parseGraph(_ data: Data) throws -> GroveSnapshot {
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard root?["errors"] == nil, let inner = root?["data"] as? [String: Any], let user = inner["user"] as? [String: Any], let login = user["login"] as? String, let collection = user["contributionsCollection"] as? [String: Any], let graph = collection["contributionCalendar"] as? [String: Any], let weeks = graph["weeks"] as? [[String: Any]] else { throw GroveError.message("找不到这个用户，或 GitHub 返回了不完整的数据。") }
        let levels = ["NONE": 0, "FIRST_QUARTILE": 1, "SECOND_QUARTILE": 2, "THIRD_QUARTILE": 3, "FOURTH_QUARTILE": 4]
        let days = weeks.flatMap { week -> [ContributionDay] in
            (week["contributionDays"] as? [[String: Any]] ?? []).compactMap {
                guard let date = $0["date"] as? String, let count = $0["contributionCount"] as? Int else { return nil }
                return ContributionDay(date: date, count: count, level: levels[$0["contributionLevel"] as? String ?? "NONE"] ?? 0)
            }
        }.sorted { $0.date < $1.date }
        guard !days.isEmpty else { throw GroveError.message("GitHub 没有返回贡献日历。") }
        let repos = (collection["commitContributionsByRepository"] as? [[String: Any]] ?? []).compactMap { item -> RepoItem? in
            guard let repo = item["repository"] as? [String: Any], let name = repo["nameWithOwner"] as? String else { return nil }
            let language = repo["primaryLanguage"] as? [String: Any]
            return RepoItem(name: name, url: repo["url"] as? String ?? "", language: language?["name"] as? String ?? "Other", color: language?["color"] as? String ?? "#789B79", count: (item["contributions"] as? [String: Any])?["totalCount"] as? Int ?? 0)
        }.sorted { $0.count > $1.count }
        func total(_ key: String) -> Int { (user[key] as? [String: Any])?["totalCount"] as? Int ?? 0 }
        return GroveSnapshot(login: login, name: user["name"] as? String ?? login, avatar: user["avatarUrl"] as? String ?? "", days: days, commits: [], repos: repos, total: graph["totalContributions"] as? Int ?? days.reduce(0) { $0 + $1.count }, publicRepos: total("repositories"), pullRequests: total("pullRequests"), issues: total("issues"), updatedAt: .now)
    }
    static func parseCommits(_ data: Data) throws -> [CommitItem] {
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let items = root?["items"] as? [[String: Any]] else { throw GroveError.message("提交数据格式异常") }
        let f = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter(); fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return items.compactMap { item in
            guard let sha = item["sha"] as? String, let commit = item["commit"] as? [String: Any], let message = commit["message"] as? String, let url = item["html_url"] as? String, let author = commit["author"] as? [String: Any], let dateString = author["date"] as? String, let date = fractional.date(from: dateString) ?? f.date(from: dateString) else { return nil }
            let repo = item["repository"] as? [String: Any]
            return CommitItem(sha: sha, message: message.components(separatedBy: .newlines).first ?? message, repository: repo?["full_name"] as? String ?? "", date: date, url: url)
        }
    }
}

enum GroveCache {
    static var directory: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("GitGrove") }
    static func url(_ login: String) -> URL { directory.appendingPathComponent("\(login.lowercased()).json") }
    static func load(_ login: String) -> GroveSnapshot? {
        guard (try? GitHubClient.validate(login)) != nil, let data = try? Data(contentsOf: url(login)) else { return nil }
        return try? JSONDecoder().decode(GroveSnapshot.self, from: data)
    }
    static func save(_ snapshot: GroveSnapshot) throws {
        guard !snapshot.isDemo else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try JSONEncoder().encode(snapshot).write(to: url(snapshot.login), options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url(snapshot.login).path)
    }
}
