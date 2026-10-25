import Foundation

enum PublicCalendar {
    static func parse(_ html: String) throws -> [ContributionDay] {
        let dayRegex = try NSRegularExpression(pattern: "<td\\b[^>]*data-date=\"([^\"]+)\"[^>]*>")
        let attrsRegex = try NSRegularExpression(pattern: "([\\w-]+)=\"([^\"]*)\"")
        let tipsRegex = try NSRegularExpression(pattern: "<tool-tip\\b[^>]*for=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</tool-tip>")
        let source = html as NSString
        var counts: [String: Int] = [:]
        for tip in tipsRegex.matches(in: html, range: NSRange(location: 0, length: source.length)) {
            let id = source.substring(with: tip.range(at: 1)), text = source.substring(with: tip.range(at: 2))
            if text.lowercased().contains("no contributions") { counts[id] = 0 }
            else if let match = text.range(of: "[0-9][0-9,]*", options: .regularExpression), let count = Int(text[match].replacingOccurrences(of: ",", with: "")) { counts[id] = count }
        }
        var result: [ContributionDay] = []
        for match in dayRegex.matches(in: html, range: NSRange(location: 0, length: source.length)) {
            let tag = source.substring(with: match.range); let nsTag = tag as NSString
            var attrs: [String: String] = [:]
            for a in attrsRegex.matches(in: tag, range: NSRange(location: 0, length: nsTag.length)) { attrs[nsTag.substring(with: a.range(at: 1))] = nsTag.substring(with: a.range(at: 2)) }
            guard let date = attrs["data-date"], let id = attrs["id"], let level = Int(attrs["data-level"] ?? ""), let count = counts[id] else { throw GroveError.message("GitHub 页面格式发生变化") }
            result.append(ContributionDay(date: date, count: count, level: level))
        }
        guard result.count >= 300 else { throw GroveError.message("贡献日历不完整") }
        return result.sorted { $0.date < $1.date }
    }
}

