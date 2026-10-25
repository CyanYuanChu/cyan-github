import SwiftUI
struct HeatmapView: View {
    var snapshot: GroveSnapshot
    var palette = GrovePalette()
    var compact = false
    var weeksToShow: Int? = nil
    var maximumCell: CGFloat = 13
    @GroveState private var hovered: String? = nil
    var columns: [[ContributionDay]] { let all = snapshot.weeks; return weeksToShow.map { Array(all.suffix($0)) } ?? all }
    var body: some View {
        GeometryReader { proxy in
            let count = max(columns.count, 1)
            let gap: CGFloat = compact ? 3 : 4
            let labelWidth: CGFloat = compact ? 0 : 22
            let cell = max(2, min(maximumCell, (proxy.size.width - labelWidth - CGFloat(count - 1) * gap) / CGFloat(count)))
            VStack(alignment: .leading, spacing: compact ? 6 : 10) {
                if !compact {
                    HStack(spacing: gap) {
                        Color.clear.frame(width: labelWidth - gap)
                        ForEach(Array(columns.enumerated()), id: \.offset) { index, week in
                            Text(monthLabel(index: index, week: week)).font(.system(size: 9, weight: .medium)).foregroundStyle(palette.secondary).fixedSize(horizontal: true, vertical: false).frame(width: cell, alignment: .leading)
                        }
                    }.frame(height: 12)
                }
                HStack(alignment: .top, spacing: gap) {
                    if !compact {
                        VStack(spacing: gap) {
                            ForEach(0..<7) { row in Text(row == 1 ? "一" : row == 3 ? "三" : row == 5 ? "五" : "").font(.system(size: 8)).foregroundStyle(palette.secondary).frame(width: labelWidth - gap, height: cell) }
                        }
                    }
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: gap) {
                            ForEach(week) { day in
                                RoundedRectangle(cornerRadius: compact ? 2 : 2.5)
                                    .fill(day.count < 0 ? .clear : palette.levels[min(4, max(0, day.level))])
                                    .frame(width: cell, height: cell)
                                    .overlay { if day.date == snapshot.todayKey() { RoundedRectangle(cornerRadius: 2.5).stroke(palette.accent, lineWidth: 1.2).padding(-1.6) } }
                                    .scaleEffect(hovered == day.id && day.count >= 0 ? 1.17 : 1)
                                    .onHover { hovered = $0 ? day.id : nil }
                                    .help(day.count < 0 ? "" : "\(day.date) · \(day.count) 次贡献")
                                    .accessibilityLabel(day.count < 0 ? "" : "\(day.date)，\(day.count) 次贡献")
                            }
                        }
                    }
                }
            }
        }.frame(height: compact ? 7 * maximumCell + 6 * 3 : 7 * 13 + 6 * 4 + 22)
    }
    private func monthLabel(index: Int, week: [ContributionDay]) -> String {
        guard let date = week.first(where: { !$0.date.hasPrefix("pad") })?.date else { return "" }
        let parts = date.split(separator: "-")
        guard parts.count == 3, let day = Int(parts[2]), let month = Int(parts[1]) else { return "" }
        if index == 0 || (day <= 7 && index >= 3) { return "\(month)月" }
        return ""
    }
}

struct ActivityBars: View {
    var days: [ContributionDay]
    var palette = GrovePalette()
    var body: some View {
        let recent = Array(days.suffix(28))
        let top = max(recent.map(\.count).max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(recent) { day in
                RoundedRectangle(cornerRadius: 2).fill(day.count == 0 ? palette.line : palette.accent.opacity(0.72))
                    .frame(height: max(3, CGFloat(day.count) / CGFloat(top) * 36)).help("\(day.date) · \(day.count) 次贡献")
            }
        }.frame(height: 38)
    }
}

