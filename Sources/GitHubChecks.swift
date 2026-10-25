import Foundation

enum SelfTests {
    @MainActor static func run() async {
        var failures = [String](); var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ label: String) { if condition() { passed += 1; print("PASS \(label)") } else { failures.append(label); print("FAIL \(label)") } }
        for username in ["octocat", "CyanYuanChu", "a", "user-name", String(repeating: "a", count: 39)] { check((try? GitHubClient.validate(username)) != nil, "valid username \(username)") }
        for username in ["", "-abc", "abc-", "a/b", "a\"b", "hello world", String(repeating: "a", count: 40)] { check((try? GitHubClient.validate(username)) == nil, "reject invalid username") }
        let graph = """
        {"data":{"user":{"login":"tester","name":null,"avatarUrl":"","repositories":{"totalCount":2},"pullRequests":{"totalCount":1},"issues":{"totalCount":0},"contributionsCollection":{"contributionCalendar":{"totalContributions":5,"weeks":[{"contributionDays":[{"date":"2026-10-13","contributionCount":0,"contributionLevel":"NONE"},{"date":"2026-10-14","contributionCount":2,"contributionLevel":"SECOND_QUARTILE"},{"date":"2026-10-15","contributionCount":3,"contributionLevel":"FOURTH_QUARTILE"},{"date":"2026-10-16","contributionCount":0,"contributionLevel":"NONE"}]}]},"commitContributionsByRepository":[]}}}}
        """
        do {
            let snapshot = try GitHubClient.parseGraph(Data(graph.utf8))
            check(snapshot.total == 5 && snapshot.name == "tester", "GraphQL nullable name fallback")
            check(snapshot.days.count == 4 && snapshot.days[1].level == 2, "GraphQL calendar and color levels")
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
            check(snapshot.streak(now: f.date(from: "2026-10-16 12:00")!) == 2, "streak continues from yesterday when today is empty")
            check(snapshot.streak(now: f.date(from: "2026-10-17 12:00")!) == 0, "streak ends after a complete missed day")
            check(snapshot.longestStreak == 2, "longest streak stops at zero")
            check(snapshot.weeks.allSatisfy { $0.count == 7 }, "partial weeks pad to seven cells")
            check(snapshot.weeks.flatMap { $0 }.filter { $0.count >= 0 }.count == 4, "padding never invents contribution days")
            let roundtrip = try JSONDecoder().decode(GroveSnapshot.self, from: JSONEncoder().encode(snapshot))
            check(roundtrip.total == 5 && roundtrip.days == snapshot.days, "offline cache round trip")
        } catch { failures.append("graph fixture: \(error)") }
        check((try? GitHubClient.parseGraph(Data("{\"errors\":[{\"message\":\"denied\"}]}".utf8))) == nil, "GraphQL errors do not display zeros as success")
        check((try? GitHubClient.parseGraph(Data("{\"data\":{\"user\":null}}".utf8))) == nil, "unknown account rejected")
        let commits = """
        {"items":[{"sha":"abcdef123","html_url":"https://github.com/test/repo/commit/abcdef123","repository":{"full_name":"test/repo"},"commit":{"message":"First line\\n\\nLong body","author":{"date":"2026-10-15T10:00:00Z"}}}]}
        """
        let items = try? GitHubClient.parseCommits(Data(commits.utf8))
        check(items?.first?.message == "First line", "commit list uses first line only")
        check(items?.first?.repository == "test/repo", "commit repository retained")
        let fractionalCommits = commits.replacingOccurrences(of: "2026-10-15T10:00:00Z", with: "2026-09-23T10:43:07.000+08:00")
        check((try? GitHubClient.parseCommits(Data(fractionalCommits.utf8)))?.count == 1, "GitHub millisecond and offset timestamps retained")
        if let index = CommandLine.arguments.firstIndex(of: "--calendar-fixture"), CommandLine.arguments.count > index + 1 {
            do {
                let html = try String(contentsOfFile: CommandLine.arguments[index + 1], encoding: .utf8)
                let parsed = try PublicCalendar.parse(html)
                check(parsed.count >= 365 && parsed.count <= 371, "real public calendar date count")
                check(parsed.reduce(0) { $0 + $1.count } == 8, "public HTML total agrees with live GraphQL total of 8")
                check(parsed.contains { $0.count == 0 && $0.date.hasSuffix("12") }, "zero contributions never confused with day of month")
            } catch { failures.append("public calendar fixture: \(error)") }
        }
        let demo = GroveSnapshot.demo()
        check(demo.days.count == 365 && demo.isDemo, "demo is explicit and covers 365 days")
        check(demo.days.reduce(0) { $0 + $1.count } == demo.total, "demo totals remain consistent")
        print("SELF_TESTS \(passed) passed, \(failures.count) failed")
        if !failures.isEmpty { exit(1) }
    }
}
