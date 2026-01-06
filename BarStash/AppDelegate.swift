import Cocoa
import ApplicationServices

/// 定义需要被“隐藏区”展示的占位项，可替换为真实业务图标。
private struct HiddenStatusItemConfig {
    let id: String
    let symbolName: String
    let tooltip: String
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var primaryItem: NSStatusItem?    // 主入口图标（菜单）
    private var chevronItem: NSStatusItem?    // 展开/收起箭头
    private var hiddenItems: [NSStatusItem] = [] // 隐藏区当前展示的项
    private var isExpanded = false            // 隐藏区展开状态
    private var attentionStates: [String: Bool] = [:] // 记录每个隐藏项是否需要突出显示

    // 可按需替换为真实的隐藏图标配置
    private let hiddenConfigs: [HiddenStatusItemConfig] = [
        .init(id: "hidden.star", symbolName: "star", tooltip: "Hidden Item 1"),
        .init(id: "hidden.bell", symbolName: "bell", tooltip: "Hidden Item 2")
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureAccessibilityPermission()
        // 初始化每个隐藏项的“需要关注”状态
        hiddenConfigs.forEach { attentionStates[$0.id] = false }
        setUpStatusItems()
    }

    private func setUpStatusItems() {
        primaryItem = makePrimaryItem()  // 主菜单
        chevronItem = makeChevronItem()  // 控制隐藏区展开/收起
        rebuildHiddenItems()             // 根据状态刷新隐藏区
    }

    private func makePrimaryItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "statusbar.text",
            accessibilityDescription: "BarStash"
        )

        // 主菜单
        let menu = NSMenu()
        menu.addItem(makeMenuItem(title: "Hide All Icons", action: #selector(hideAllIcons)))
        menu.addItem(makeMenuItem(title: "Show Hidden Icons", action: #selector(showHiddenIcons)))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: "Quit BarStash", action: #selector(quitApp), key: "q"))

        item.menu = menu
        return item
    }

    private func makeChevronItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.action = #selector(toggleHiddenArea)
            button.target = self
            button.toolTip = "展开/收起隐藏图标"
        }
        updateChevronIcon(on: item)
        return item
    }

    private func makeMenuItem(title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Hidden area handling

    @objc private func toggleHiddenArea() {
        isExpanded.toggle()
        if let chevronItem {
            updateChevronIcon(on: chevronItem)
        }
        rebuildHiddenItems()
    }

    private func updateChevronIcon(on item: NSStatusItem) {
        let symbol = isExpanded ? "chevron.left" : "chevron.right"
        item.button?.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: isExpanded ? "Collapse Hidden Icons" : "Show Hidden Icons"
        )
    }

    private func rebuildHiddenItems() {
        hiddenItems.forEach { NSStatusBar.system.removeStatusItem($0) }
        hiddenItems.removeAll()

        guard isExpanded else { return }

        hiddenConfigs.forEach { config in
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.image = NSImage(
                systemSymbolName: config.symbolName,
                accessibilityDescription: config.tooltip
            )
            item.button?.toolTip = config.tooltip

            // 如果该隐藏项有需要关注的状态，用红色强调并加上点提示
            if attentionStates[config.id] == true {
                item.button?.contentTintColor = .systemRed
                item.button?.title = "•"
            } else {
                item.button?.contentTintColor = nil
                item.button?.title = ""
            }
            hiddenItems.append(item)
        }
    }

    /// 供外部调用：当某个隐藏项有数字角标/通知时，自动展开并高亮。
    /// - Parameters:
    ///   - id: 对应 `hiddenConfigs` 的 id
    ///   - hasAttention: 是否需要高亮提示
    func markHiddenItemAttention(id: String, hasAttention: Bool) {
        attentionStates[id] = hasAttention
        // 有新提示时自动展开隐藏区
        if hasAttention && !isExpanded {
            isExpanded = true
            if let chevronItem { updateChevronIcon(on: chevronItem) }
        }
        rebuildHiddenItems()
    }

    @objc private func hideAllIcons() {
        // TODO: 替换为真实隐藏逻辑
        NSLog("Hide All Icons tapped")
    }

    @objc private func showHiddenIcons() {
        // TODO: 替换为真实恢复逻辑
        NSLog("Show Hidden Icons tapped")
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func ensureAccessibilityPermission() {
        // 请求辅助功能权限，未授权时系统会弹窗提示
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            NSLog("Awaiting accessibility permission; user will see system prompt.")
        }
    }
}

