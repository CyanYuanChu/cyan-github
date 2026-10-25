import SwiftUI
import WidgetKit

struct NativePalette {
    var dark: Bool
    var text: Color { Color(hex: dark ? "E7EEE5" : "253B30") }
    var secondary: Color { Color(hex: dark ? "A0B3A5" : "768276") }
    var accent: Color { Color(hex: dark ? "B9DA8C" : "487341") }
    var background: Color { Color(hex: dark ? "1B2822" : "F8FAF5") }
    var levels: [Color] { (dark ? ["293A30", "405C3B", "648A48", "94BC65", "C7E795"] : ["E7ECE0", "D1E3B6", "A2C67C", "719D50", "456D3D"]).map { Color(hex: $0) } }
}

struct NativeHeatmap: View {
    var weeks: [[ContributionDay]]
    var palette: NativePalette
    var body: some View {
        GeometryReader { proxy in
            let gap: CGFloat = 2
            let side = max(1, min((proxy.size.width - CGFloat(max(weeks.count-1, 0))*gap)/CGFloat(max(weeks.count, 1)), (proxy.size.height-6*gap)/7))
            HStack(alignment: .top, spacing: gap) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: gap) {
                        ForEach(week) { day in
                            RoundedRectangle(cornerRadius: min(2, side/4))
                                .fill(day.count < 0 ? .clear : palette.levels[min(4,max(0,day.level))])
                                .frame(width: side, height: side)
                                .accessibilityLabel(day.count < 0 ? "" : "\(day.date)，\(day.count) 次贡献")
                        }
                    }
                }
            }.widgetAccentable()
        }
    }
}

struct NativeContributionView: View {
    var snapshot: GroveSnapshot
    var family: WidgetFamily
    var dark: Bool
    var preview = false
    var error: String? = nil
    var p: NativePalette { NativePalette(dark: dark) }
    var body: some View {
        content
            .containerBackground(p.background, for: .widget)
            .widgetURL(URL(string: "cyan-github://overview"))
    }
    // The host preview and actual extension render the same content.
    var content: some View {
        Group {
            if snapshot.days.isEmpty { emptyState }
            else {
                switch family {
                case .systemSmall: small
                case .systemMedium: medium
                default: large
                }
            }
        }
        .foregroundStyle(p.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill").foregroundStyle(p.accent).widgetAccentable()
            Text("Cyan GitHub").font(.system(size: 12, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
            if preview { Text("预览").font(.system(size: 8)).foregroundStyle(p.secondary) }
            else if error != nil { Image(systemName: "wifi.exclamationmark").foregroundStyle(.orange).font(.system(size: 10)).accessibilityLabel("离线，显示缓存") }
        }
    }
    var footer: some View {
        HStack {
            Text("@\(snapshot.login)").lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 3)
            if family != .systemSmall { Text("\(snapshot.updatedAt.formatted(date: .omitted, time: .shortened))").monospacedDigit() }
        }.font(.system(size: 9)).foregroundStyle(p.secondary)
    }
    var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(snapshot.today)").font(.system(size: 30, weight: .light, design: .rounded)).monospacedDigit()
                Text("今日贡献").font(.system(size: 9)).foregroundStyle(p.secondary)
            }
            NativeHeatmap(weeks: Array(snapshot.weeks.suffix(14)), palette: p).frame(maxHeight: .infinity)
            footer
        }
    }
    var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                header
                Text("\(snapshot.total)").font(.system(size: 25, weight: .light, design: .rounded)).monospacedDigit()
                Text("次 / 年").font(.system(size: 9)).foregroundStyle(p.secondary)
            }
            NativeHeatmap(weeks: Array(snapshot.weeks.suffix(26)), palette: p).frame(maxHeight: .infinity)
            HStack {
                Text("@\(snapshot.login)").lineLimit(1)
                Spacer(minLength: 4)
                Text("今日 \(snapshot.today) · 连续 \(snapshot.currentStreak) 天").fixedSize()
            }.font(.system(size: 9)).foregroundStyle(p.secondary)
        }
    }
    var large: some View {
        let weeks = snapshot.weeks
        let midpoint = (weeks.count + 1)/2
        return VStack(alignment: .leading, spacing: 12) {
            header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(snapshot.total)").font(.system(size: 37, weight: .light, design: .rounded)).monospacedDigit()
                Text("次贡献 / 过去一年").font(.system(size: 10)).foregroundStyle(p.secondary)
            }
            VStack(alignment: .leading, spacing: 5) {
                periodLabel(Array(weeks.prefix(midpoint)))
                NativeHeatmap(weeks: Array(weeks.prefix(midpoint)), palette: p)
                periodLabel(Array(weeks.dropFirst(midpoint)))
                NativeHeatmap(weeks: Array(weeks.dropFirst(midpoint)), palette: p)
            }.frame(maxHeight: .infinity)
            HStack {
                stat("今日", value: snapshot.today)
                Spacer()
                stat("近 7 天", value: snapshot.lastSeven)
                Spacer()
                stat("连续天数", value: snapshot.currentStreak)
            }
            footer
        }
    }
    func stat(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(value)").font(.system(size: 20, weight: .medium, design: .rounded)).monospacedDigit()
            Text(title).font(.system(size: 9)).foregroundStyle(p.secondary)
        }
    }
    func periodLabel(_ weeks: [[ContributionDay]]) -> some View {
        let dates = weeks.flatMap { $0 }.filter { $0.count >= 0 }.map(\.date)
        return Text("\(dates.first ?? "") — \(dates.last ?? "")").font(.system(size: 8)).foregroundStyle(p.secondary)
    }
    var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Spacer(minLength: 0)
            Text("等待同步").font(.system(size: 20, weight: .medium))
            Text(error ?? "右键编辑小组件，设置 GitHub 用户名。").font(.system(size: 10)).foregroundStyle(p.secondary)
            Spacer(minLength: 0)
        }
    }
}
