import SwiftUI
import WidgetKit

struct GroveRootView: View {
    @ObservedObject var store: GroveStore
    var palette: GrovePalette { store.palette }
    var exportMode = false
    var embedded = false
    var body: some View {
        HStack(spacing: 0) {
            if !embedded { sidebar }
            Group {
                if exportMode { mainContent } else { ScrollView { mainContent } }
            }.background(palette.background)
        }
        .background(palette.background)
        .foregroundStyle(palette.text)
        .font(.system(size: 13))
        .preferredColorScheme(store.dark ? .dark : .light)
        .frame(minWidth: embedded ? 0 : 1080, minHeight: embedded ? 0 : 740)
    }
    var mainContent: some View {
                VStack(alignment: .leading, spacing: 24) {
                    if embedded { HStack { nav("总览", icon: "leaf", id: "overview"); nav("最近提交", icon: "arrow.triangle.branch", id: "activity"); nav("桌面组件", icon: "rectangle.on.rectangle", id: "widgets"); nav("账户设置", icon: "person", id: "settings") } }
                    toolbar
                    if store.demo { banner("当前是演示数据，用于预览界面", icon: "sparkles", warning: false) }
                    if let error = store.error { banner(error + (store.snapshot.login.isEmpty ? "" : " 正在显示上次同步的数据。"), icon: "wifi.exclamationmark", warning: true) }
                    if let notice = store.notice { banner(notice, icon: "info.circle", warning: false) }
                    if store.selected == "settings" { SettingsView(store: store) }
                    else if store.selected == "widgets" { WidgetStudioView(store: store) }
                    else {
                        greeting
                        if store.loading && store.snapshot.days.isEmpty { loadingCard }
                        else if store.snapshot.days.isEmpty { emptyCard }
                        else {
                            statRow
                            contributionCard
                            if store.selected == "activity" { ActivityList(store: store, limit: 12) }
                            else {
                                HStack(alignment: .top, spacing: 18) {
                                    ActivityList(store: store, limit: 4).frame(maxWidth: .infinity)
                                    repositoryCard.frame(width: 255)
                                }
                            }
                            footer
                        }
                    }
                }.padding(.horizontal, 32).padding(.top, 30).padding(.bottom, 24).frame(maxWidth: 1050)
                .frame(maxWidth: .infinity)
    }
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) { GroveMark(); VStack(alignment: .leading, spacing: 3) { Text("Cyan GitHub").font(.system(size: 19, weight: .semibold, design: .rounded)); Text("GITHUB WORKSPACE").font(.system(size: 7.5, weight: .medium)).tracking(1.1).foregroundStyle(palette.secondary) } }.padding(.bottom, 42)
            Text("工作空间").font(.system(size: 10, weight: .medium)).foregroundStyle(palette.secondary).padding(.leading, 12).padding(.bottom, 12)
            Text("GITHUB").font(.system(size:9, weight:.medium)).foregroundStyle(palette.secondary).padding(.leading,12).padding(.top,18).padding(.bottom,10)
            nav("代码足迹", icon: "leaf", id: "overview")
            nav("最近提交", icon: "arrow.triangle.branch", id: "activity")
            nav("桌面小组件", icon: "rectangle.on.rectangle", id: "widgets")
            Spacer()
            VStack(alignment: .leading, spacing: 11) {
                Image(systemName: "leaf").font(.system(size: 28, weight: .ultraLight)).foregroundStyle(palette.accent)
                Text("保持好奇，\n慢慢生长。").font(.system(size: 18, weight: .light)).lineSpacing(5)
                Text("每一次微小的推进，\n都值得被看见。").font(.system(size: 10)).lineSpacing(4).foregroundStyle(palette.secondary)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(palette.hero.opacity(0.65), in: RoundedRectangle(cornerRadius: 18)).padding(.bottom, 24)
            nav("偏好设置", icon: "slider.horizontal.3", id: "settings")
            Rectangle().fill(palette.line).frame(height: 1).padding(.vertical, 16)
            HStack(spacing: 9) {
                ZStack { Circle().fill(palette.soft); Text(String((store.snapshot.login.isEmpty ? store.login : store.snapshot.login).prefix(1)).uppercased()).font(.system(size: 12, weight: .semibold)).foregroundStyle(palette.accent) }.frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 3) { Text(store.snapshot.login.isEmpty ? store.login : store.snapshot.login).font(.system(size: 11, weight: .medium)).lineLimit(1); Text(store.demo ? "演示账户" : "GitHub 已连接").font(.system(size: 9)).foregroundStyle(palette.secondary) }
            }
        }.padding(.horizontal, 18).padding(.top, 44).padding(.bottom, 22).frame(width: 198).background(palette.sidebar)
    }
    func nav(_ title: String, icon: String, id: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.16)) { store.selected = id } } label: {
            HStack(spacing: 10) { Image(systemName: icon).font(.system(size: 13, weight: .medium)).frame(width: 18); Text(title).font(.system(size: 12, weight: store.selected == id ? .semibold : .regular)); Spacer(); if store.selected == id { Circle().fill(palette.accent).frame(width: 4, height: 4) } }.foregroundStyle(store.selected == id ? palette.accent : palette.secondary).padding(.horizontal, 12).padding(.vertical, 12).background(store.selected == id ? palette.card.opacity(0.83) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain).padding(.bottom, 5)
    }
    var toolbar: some View {
        HStack {
            Text("工作台").foregroundStyle(palette.secondary); Text("/").foregroundStyle(palette.secondary.opacity(0.5)); Text(store.selected == "home" ? "我的 Grove" : store.selected == "system" ? "系统与菜单栏" : store.selected == "codex" ? "Codex 驾驶舱" : store.selected == "passport" ? "AI Passport" : store.selected == "commands" ? "快速指令" : store.selected == "settings" ? "偏好设置" : store.selected == "widgets" ? "桌面小组件" : store.selected == "activity" ? "最近提交" : "总览").fontWeight(.medium)
            Spacer()
            Button { withAnimation { store.dark.toggle() } } label: { Image(systemName: store.dark ? "sun.max" : "moon").frame(width: 30, height: 30) }.buttonStyle(.plain).help("切换明暗主题").accessibilityLabel("切换明暗主题")
            Button { Task { await store.refresh() } } label: { HStack(spacing: 6) { Image(systemName: "arrow.clockwise"); Text(store.loading ? "同步中" : "刷新") }.font(.system(size: 11, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 8).background(palette.card, in: Capsule()).overlay(Capsule().stroke(palette.line)) }.buttonStyle(.plain).disabled(store.loading || store.demo)
        }.font(.system(size: 11))
    }
    var greeting: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR GITHUB, AT A GLANCE").font(.system(size: 9, weight: .semibold)).tracking(2.2).foregroundStyle(palette.secondary)
                Text(store.selected == "activity" ? "让每次提交，有迹可循。" : "每一小步，都算数。").font(.system(size: 28, weight: .medium))
                Text("@\(store.snapshot.login.isEmpty ? store.login : store.snapshot.login) · 你的代码足迹与日常进展").font(.system(size: 12)).foregroundStyle(palette.secondary)
            }
            Spacer()
            CapsuleLabel(text: "过去一年", icon: "calendar", palette: palette).padding(.bottom, 2)
        }.padding(.top, 4)
    }
    var statRow: some View {
        HStack(spacing: 14) {
            stat("年度贡献", value: store.snapshot.total, unit: "次", detail: "过去一年的积累", symbol: "square.grid.3x3.fill")
            stat("近 7 天", value: store.snapshot.lastSeven, unit: "次", detail: "最近一周的步伐", symbol: "chart.bar.xaxis")
            stat("连续贡献", value: store.snapshot.currentStreak, unit: "天", detail: "最长 \(store.snapshot.longestStreak) 天", symbol: "flame")
            stat("活跃天数", value: store.snapshot.activeDays, unit: "天", detail: "有贡献的日子", symbol: "sun.max")
        }
    }
    func stat(_ title: String, value: Int, unit: String, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack { Text(title).font(.system(size: 11)).foregroundStyle(palette.secondary); Spacer(); Image(systemName: symbol).font(.system(size: 13, weight: .regular)).foregroundStyle(palette.accent.opacity(0.8)) }
            HStack(alignment: .firstTextBaseline, spacing: 5) { Text("\(value)").font(.system(size: 31, weight: .regular, design: .rounded)).monospacedDigit(); Text(unit).font(.system(size: 10)).foregroundStyle(palette.secondary) }
            Text(detail).font(.system(size: 9)).foregroundStyle(palette.secondary)
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(palette.card, in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.line.opacity(0.8)))
    }
    var contributionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) { Text("生长日历").font(.system(size: 15, weight: .semibold)); Text("一年里的努力，藏在这些小小的方格里。").font(.system(size: 10)).foregroundStyle(palette.secondary) }
                Spacer(); HStack(spacing: 5) { Circle().fill(palette.accent).frame(width: 5, height: 5); Text("今日 \(store.snapshot.today) 次贡献").font(.system(size: 10)).foregroundStyle(palette.accent) }.padding(.top, 4)
            }
            HeatmapView(snapshot: store.snapshot, palette: palette).padding(.top, 3)
            HStack {
                Text(dateRange).font(.system(size: 9)).foregroundStyle(palette.secondary)
                Spacer()
                HStack(spacing: 4) { Text("少").padding(.trailing, 3); ForEach(0..<5) { i in RoundedRectangle(cornerRadius: 2).fill(palette.levels[i]).frame(width: 9, height: 9) }; Text("多").padding(.leading, 3) }.font(.system(size: 9)).foregroundStyle(palette.secondary)
            }
        }.padding(22).background(palette.card, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.line.opacity(0.8)))
    }
    var dateRange: String {
        guard let first = store.snapshot.days.first?.date, let last = store.snapshot.days.last?.date else { return "" }
        return "\(first.replacingOccurrences(of: "-", with: ".")) — \(last.replacingOccurrences(of: "-", with: "."))"
    }
    var repositoryCard: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack { Text("活跃仓库").font(.system(size: 14, weight: .semibold)); Spacer(); Image(systemName: "shippingbox").foregroundStyle(palette.secondary) }
            if store.snapshot.repos.isEmpty {
                Text("贡献日历里暂时没有\n可见的提交仓库。").font(.system(size: 11)).foregroundStyle(palette.secondary).lineSpacing(5).padding(.vertical, 12)
            } else {
                ForEach(store.snapshot.repos.prefix(3)) { repo in
                    Button { store.open(repo.url) } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(repo.name.components(separatedBy: "/").last ?? repo.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                            HStack(spacing: 5) { Circle().fill(Color(hex: repo.color)).frame(width: 5, height: 5); Text(repo.language); Spacer(); Text("\(repo.count) commits").monospacedDigit() }.font(.system(size: 9)).foregroundStyle(palette.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            }
            Rectangle().fill(palette.line).frame(height: 1)
            HStack(spacing: 12) { Label("\(store.snapshot.pullRequests) PR", systemImage: "arrow.triangle.pull"); Label("\(store.snapshot.issues) Issue", systemImage: "circle.dotted") }.font(.system(size: 10)).foregroundStyle(palette.secondary)
            Text("由你创建 · 当前未关闭").font(.system(size: 8)).foregroundStyle(palette.secondary.opacity(0.8))
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(palette.card, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.line.opacity(0.8)))
    }
    var footer: some View {
        HStack(spacing: 5) { Circle().fill(store.error == nil ? palette.accent : Color.orange).frame(width: 4, height: 4); Text(store.snapshot.isDemo ? "演示模式 · 不会保存到真实账户" : "更新于 \(store.snapshot.updatedAt.formatted(date: .omitted, time: .shortened)) · 每 15 分钟同步"); Spacer(); Text("贡献包含 Commit、PR、Issue 等活动").help("贡献日历遵循 GitHub 统计规则；最近提交列表按作者搜索，范围可能不同。") }.font(.system(size: 9)).foregroundStyle(palette.secondary)
    }
    var loadingCard: some View { HStack(spacing: 12) { ProgressView().controlSize(.small); Text("正在整理你的 GitHub 足迹…").foregroundStyle(palette.secondary) }.frame(maxWidth: .infinity, minHeight: 280).background(palette.card, in: RoundedRectangle(cornerRadius: 18)) }
    var emptyCard: some View { VStack(spacing: 16) { Image(systemName: "leaf").font(.system(size: 36, weight: .ultraLight)).foregroundStyle(palette.accent); Text("从连接 GitHub 开始").font(.system(size: 19, weight: .medium)); Text("在偏好设置中输入用户名，再同步你的贡献记录。").foregroundStyle(palette.secondary); Button("打开偏好设置") { store.selected = "settings" }.buttonStyle(.borderedProminent).tint(palette.accent) }.frame(maxWidth: .infinity, minHeight: 280).background(palette.card, in: RoundedRectangle(cornerRadius: 18)) }
    func banner(_ text: String, icon: String, warning: Bool) -> some View { HStack(alignment: .top, spacing: 9) { Image(systemName: icon); Text(text).fixedSize(horizontal: false, vertical: true); Spacer() }.font(.system(size: 11)).foregroundStyle(warning ? Color(hex: store.dark ? "EDC38D" : "946124") : palette.accent).padding(13).background(warning ? Color.orange.opacity(0.08) : palette.soft, in: RoundedRectangle(cornerRadius: 10)) }
}

struct ActivityList: View {
    @ObservedObject var store: GroveStore
    var limit: Int
    var p: GrovePalette { store.palette }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text("最近提交").font(.system(size: 14, weight: .semibold)); Spacer(); Button { store.open("https://github.com/\(store.snapshot.login)?tab=overview") } label: { Image(systemName: "arrow.up.right").font(.system(size: 11)) }.buttonStyle(.plain).help("在 GitHub 查看") }.padding(.bottom, 8)
            if let error = store.snapshot.activityError { Text(error).font(.system(size: 11)).foregroundStyle(p.secondary).padding(.vertical, 24) }
            else if store.snapshot.commits.isEmpty { Text("暂时没有可见的提交。\n私有或未被搜索索引收录的提交可能不会出现在这里。").font(.system(size: 11)).foregroundStyle(p.secondary).lineSpacing(5).padding(.vertical, 24) }
            else {
                ForEach(store.snapshot.commits.prefix(limit)) { commit in
                    Button { store.open(commit.url) } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "arrow.triangle.branch").font(.system(size: 11)).foregroundStyle(p.accent).frame(width: 27, height: 27).background(p.soft, in: RoundedRectangle(cornerRadius: 8)).padding(.top, 1)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(commit.message).font(.system(size: 11, weight: .medium)).foregroundStyle(p.text).lineLimit(1)
                                HStack(spacing: 7) { Text(commit.repository.components(separatedBy: "/").last ?? commit.repository).lineLimit(1); Text(String(commit.sha.prefix(7))).font(.system(size: 9, design: .monospaced)).foregroundStyle(p.accent).padding(.horizontal, 5).padding(.vertical, 2).background(p.soft, in: RoundedRectangle(cornerRadius: 4)); Spacer(minLength: 0); Text(relative(commit.date)).fixedSize() }.font(.system(size: 9)).foregroundStyle(p.secondary)
                            }
                        }.padding(.vertical, 12).contentShape(Rectangle())
                    }.buttonStyle(.plain).help(commit.message + "\n" + commit.repository)
                    if commit.id != store.snapshot.commits.prefix(limit).last?.id { Rectangle().fill(p.line).frame(height: 1) }
                }
            }
            if limit == 4 && store.snapshot.commits.count > 4 { Button("查看全部提交  →") { store.selected = "activity" }.font(.system(size: 10, weight: .medium)).foregroundStyle(p.accent).buttonStyle(.plain).padding(.top, 12) }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(p.card, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(p.line.opacity(0.8)))
    }
    func relative(_ date: Date) -> String { let f = RelativeDateTimeFormatter(); f.locale = Locale(identifier: "zh_CN"); f.unitsStyle = .short; return f.localizedString(for: date, relativeTo: .now) }
}

struct SettingsView: View {
    @ObservedObject var store: GroveStore
    @GroveState private var input = ""
    var p: GrovePalette { store.palette }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("让这里，更像你的桌面。").font(.system(size: 27, weight: .medium))
            StartupSettingsView(manager: store.startup, p: p)
            VStack(alignment: .leading, spacing: 18) {
                Label("GitHub 账户", systemImage: "person.crop.circle").font(.system(size: 15, weight: .semibold))
                Text("使用本机已登录的 GitHub CLI 同步，不需要在这里粘贴令牌。").font(.system(size: 11)).foregroundStyle(p.secondary)
                HStack(spacing: 10) { TextField("GitHub 用户名", text: $input).textFieldStyle(.roundedBorder).frame(maxWidth: 300).onSubmit { store.connect(input) }; Button(store.loading ? "同步中…" : "连接并同步") { store.connect(input) }.buttonStyle(.borderedProminent).tint(p.accent).disabled(store.loading || store.demo) }
                Text("若认证失效，在终端运行 gh auth login 后重试。").font(.system(size: 10)).foregroundStyle(p.secondary)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(p.card, in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 18) {
                Label("外观与预览", systemImage: "paintpalette").font(.system(size: 15, weight: .semibold))
                Toggle("深色主题 · Forest at night", isOn: $store.dark).toggleStyle(.switch).tint(p.accent)
                Divider()
                Toggle("演示数据", isOn: Binding(get: { store.demo }, set: { store.setDemo($0) })).toggleStyle(.switch).tint(p.accent)
                Text("演示模式会明确标记，不会写入真实数据缓存；退出后自动恢复你的账户。").font(.system(size: 10)).foregroundStyle(p.secondary)
            }.font(.system(size: 12)).padding(24).background(p.card, in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 10) { Text("关于 Cyan GitHub").font(.system(size: 13, weight: .semibold)); Text("为 Cyan 定制的个人功能合集 · 原生 SwiftUI\n系统监控每 2 秒、额度每 5 分钟、GitHub 每 15 分钟刷新\n贡献日历与最近提交遵循不同的 GitHub 统计规则。离线时保留上次结果并显示更新时间。").font(.system(size: 11)).lineSpacing(6).foregroundStyle(p.secondary) }.padding(24)
        }.onAppear { input = store.login }
    }
}

struct WidgetStudioView: View {
    @ObservedObject var store: GroveStore
    @GroveState private var size = 1
    var p: GrovePalette { store.palette }
    var family: WidgetFamily { size == 0 ? .systemSmall : size == 1 ? .systemMedium : .systemLarge }
    var previewSize: CGSize { size == 0 ? CGSize(width: 170, height: 170) : size == 1 ? CGSize(width: 360, height: 170) : CGSize(width: 360, height: 360) }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 9) {
                Text("把进展，放在眼前。").font(.system(size: 27, weight: .medium))
                Text("Cyan GitHub 已包含原生桌面小组件，和工作台一起安装。").font(.system(size: 12)).foregroundStyle(p.secondary)
            }
            VStack(spacing: 22) {
                HStack {
                    Text("外观预览").font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("预览尺寸", selection: $size) {
                        Text("小").tag(0); Text("中").tag(1); Text("大").tag(2)
                    }.pickerStyle(.segmented).frame(width: 180)
                }
                NativeContributionView(snapshot: store.snapshot, family: family, dark: store.dark, preview: true).content
                    .padding(16).frame(width: previewSize.width, height: previewSize.height)
                    .background(NativePalette(dark: store.dark).background, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.07), radius: 16, y: 8)
                Text("此处为内容预览；桌面上的尺寸和排列由 macOS 管理。").font(.system(size: 10)).foregroundStyle(p.secondary)
            }.padding(24).frame(maxWidth: .infinity).background(p.hero, in: RoundedRectangle(cornerRadius: 24))
            VStack(alignment: .leading, spacing: 17) {
                Label("添加到桌面", systemImage: "plus.rectangle.on.rectangle").font(.system(size: 15, weight: .semibold))
                instruction("1", "在桌面空白处右键，选择「编辑小组件」。")
                instruction("2", "搜索 Cyan GitHub，选择小、中或大尺寸并添加。")
                instruction("3", "右键组件 →「编辑小组件」，设置 GitHub 用户名和主题。")
                Text("点击桌面组件即可打开这个工作台；退出主应用后，组件仍由系统调度刷新。").font(.system(size: 11)).foregroundStyle(p.secondary).lineSpacing(4)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(p.card, in: RoundedRectangle(cornerRadius: 18))
            Text("桌面组件显示公开贡献日历，账户可逐个配置；工作台通过本机 GitHub CLI 显示提交与仓库明细。组件约每 30 分钟请求刷新，实际时机由系统安排。").font(.system(size: 10)).foregroundStyle(p.secondary).lineSpacing(5)
        }
    }
    func instruction(_ number: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(number).font(.system(size: 10, weight: .semibold)).foregroundStyle(p.accent).frame(width: 23, height: 23).background(p.soft, in: Circle())
            Text(text).font(.system(size: 12))
        }
    }
}
