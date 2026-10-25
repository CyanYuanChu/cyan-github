import SwiftUI
struct HeatmapView: View {
    var snapshot: GroveSnapshot
    var palette = GrovePalette()
    var compact = false
    var weeksToShow: Int? = nil
    var maximumCell: CGFloat = 13
    @GroveState private var hovered: String? = nil
    var columns: [[ContributionDay]] { let all = snapshot.weeks; return weeksToShow.map { Array(all.suffix($0)) } ?? all }
    private var gap: CGFloat { compact ? 3 : 4 }
    private var labelWidth: CGFloat { compact ? 0 : 22 }
    private var gridHeight: CGFloat { compact ? 7 * maximumCell + 18 : 137 }
    var body: some View {
        GeometryReader { proxy in
            grid(cell: cellSize(width: proxy.size.width))
        }.frame(height: gridHeight)
    }
    private func cellSize(width: CGFloat) -> CGFloat {
        let count = max(columns.count, 1)
        let available = width - labelWidth - CGFloat(count - 1) * gap
        return max(2, min(maximumCell, available / CGFloat(count)))
    }
    private func grid(cell: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            if !compact { monthLabels(cell: cell) }
            HStack(alignment: .top, spacing: gap) {
                if !compact { weekdayLabels(cell: cell) }
                ForEach(Array(columns.enumerated()), id: \.offset) { item in
                    weekColumn(item.element, cell: cell)
                }
            }
        }
    }
    private func monthLabels(cell: CGFloat) -> some View {
        HStack(spacing: gap) {
            Color.clear.frame(width: labelWidth - gap)
            ForEach(Array(columns.enumerated()), id: \.offset) { item in
                Text(monthLabel(index: item.offset, week: item.element))
                    .font(.system(size: 9, weight: .medium)).foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: true, vertical: false).frame(width: cell, alignment: .leading)
            }
        }.frame(height: 12)
    }
    private func weekdayLabels(cell: CGFloat) -> some View {
        VStack(spacing: gap) {
            ForEach(0..<7) { row in
                Text(row == 1 ? "一" : row == 3 ? "三" : row == 5 ? "五" : "")
                    .font(.system(size: 8)).foregroundStyle(palette.secondary)
                    .frame(width: labelWidth - gap, height: cell)
            }
        }
    }
    private func weekColumn(_ week: [ContributionDay], cell: CGFloat) -> some View {
        VStack(spacing: gap) { ForEach(week) { day in dayCell(day, cell: cell) } }
    }
    private func dayCell(_ day: ContributionDay, cell: CGFloat) -> some View {
        let color: Color = day.count < 0 ? Color.clear : palette.levels[min(4, max(0, day.level))]
        let label = day.count < 0 ? "" : "\(day.date) · \(day.count) 次贡献"
        return RoundedRectangle(cornerRadius: compact ? 2 : 2.5)
            .fill(color).frame(width: cell, height: cell)
            .overlay {
                if day.date == snapshot.todayKey() {
                    RoundedRectangle(cornerRadius: 2.5).stroke(palette.accent, lineWidth: 1.2).padding(-1.6)
                }
            }
            .scaleEffect(hovered == day.id && day.count >= 0 ? 1.17 : 1)
            .onHover { hovered = $0 ? day.id : nil }
            .help(label).accessibilityLabel(label)
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

