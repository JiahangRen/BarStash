import Cocoa
import ApplicationServices
import Carbon

/// 定义需要被"隐藏区"展示的占位项，可替换为真实业务图标。
private struct HiddenStatusItemConfig {
    let id: String
    let symbolName: String
    let tooltip: String
    let defaultPinned: Bool
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var primaryItem: NSStatusItem?    // 主入口图标（菜单）
    private var chevronItem: NSStatusItem?    // 展开/收起箭头
    private var allStatusItems: [String: NSStatusItem] = [:] // 所有状态栏项的字典，key 为 config.id
    private var isExpanded = false            // 隐藏区展开状态
    private var attentionStates: [String: Bool] = [:] // 记录每个隐藏项是否需要突出显示
    private var pinnedIds: Set<String> = []   // 用户偏好：哪些 ID 常驻外显
    
    // 快捷键和定时器
    private var hotKeyRef: EventHotKeyRef?
    private var autoCollapseTimer: Timer?
    private var idleTimer: Timer?
    
    // 用户偏好
    private var autoCollapseEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "BarStashAutoCollapseEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "BarStashAutoCollapseEnabled") }
    }
    private var autoCollapseDelay: TimeInterval {
        get {
            let saved = UserDefaults.standard.double(forKey: "BarStashAutoCollapseDelay")
            return saved > 0 ? saved : 5.0 // 默认 5 秒
        }
        set { UserDefaults.standard.set(newValue, forKey: "BarStashAutoCollapseDelay") }
    }
    private var idleCollapseEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "BarStashIdleCollapseEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "BarStashIdleCollapseEnabled") }
    }
    private var idleCollapseDelay: TimeInterval {
        get {
            let saved = UserDefaults.standard.double(forKey: "BarStashIdleCollapseDelay")
            return saved > 0 ? saved : 30.0 // 默认 30 秒
        }
        set { UserDefaults.standard.set(newValue, forKey: "BarStashIdleCollapseDelay") }
    }

    // 可按需替换为真实的隐藏图标配置
    private let hiddenConfigs: [HiddenStatusItemConfig] = [
        .init(id: "hidden.star", symbolName: "star", tooltip: "Hidden Item 1", defaultPinned: false),
        .init(id: "hidden.bell", symbolName: "bell", tooltip: "Hidden Item 2", defaultPinned: false),
        .init(id: "hidden.gear", symbolName: "gearshape", tooltip: "Hidden Item 3", defaultPinned: true)
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查是否从 Launcher 启动，如果是则退出 Launcher
        if Bundle.main.bundleIdentifier == "com.example.BarStash" {
            let launcherIdentifier = "com.example.BarStashLauncher"
            let runningApps = NSWorkspace.shared.runningApplications
            let launcherRunning = runningApps.contains { $0.bundleIdentifier == launcherIdentifier }
            
            if launcherRunning {
                DistributedNotificationCenter.default().post(
                    name: Notification.Name("killLauncher"),
                    object: Bundle.main.bundleIdentifier!
                )
            }
        }
        
        ensureAccessibilityPermission()
        // 初始化每个隐藏项的"需要关注"状态
        hiddenConfigs.forEach { attentionStates[$0.id] = false }
        pinnedIds = loadPinnedIds()
        setUpStatusItems()
        setupGlobalHotkey()
        setupAutoCollapse()
        setupIdleCollapse()
        
        // 监听系统唤醒通知
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        unregisterHotkey()
        stopTimers()
        // 清理所有状态栏项
        allStatusItems.values.forEach { NSStatusBar.system.removeStatusItem($0) }
        allStatusItems.removeAll()
    }

    private func setUpStatusItems() {
        primaryItem = makePrimaryItem()  // 主菜单
        chevronItem = makeChevronItem()  // 控制隐藏区展开/收起
        rebuildStatusItems()             // 根据状态刷新展示
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
        menu.addItem(makeCustomizeMenu()) // 允许选择哪些图标常驻/可隐藏
        menu.addItem(.separator())
        menu.addItem(makeMenuItem(title: "Preferences...", action: #selector(showPreferences), key: ","))
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
            button.toolTip = "展开/收起隐藏图标 (⌘+T)"
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
            updateChevronIcon(on: chevronItem, animated: true)
        }
        rebuildStatusItems()
        resetAutoCollapseTimer()
        resetIdleTimer()
    }
    
    private func updateChevronIcon(on item: NSStatusItem, animated: Bool = false) {
        let symbol = isExpanded ? "chevron.left" : "chevron.right"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: isExpanded ? "Collapse Hidden Icons" : "Show Hidden Icons")
        
        if animated {
            // 简单的淡入淡出动画
            item.button?.alphaValue = 0.5
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                item.button?.animator().alphaValue = 1.0
            }
        }
        
        item.button?.image = image
    }

    private func rebuildStatusItems() {
        // 移除所有现有的状态栏项
        allStatusItems.values.forEach { NSStatusBar.system.removeStatusItem($0) }
        allStatusItems.removeAll()
        
        // 根据展开状态和 pinned 状态重新创建需要的项
        hiddenConfigs.forEach { config in
            let shouldShow: Bool
            if pinnedIds.contains(config.id) {
                // pinned 的项始终显示
                shouldShow = true
            } else {
                // 未 pinned 的项只在展开时显示
                shouldShow = isExpanded
            }
            
            if shouldShow {
                // 创建并保存状态栏项
                allStatusItems[config.id] = buildStatusItem(for: config)
            }
        }
    }
    
    private func updateStatusItem(_ item: NSStatusItem, for config: HiddenStatusItemConfig) {
        // 更新项的显示状态（如高亮等）
        if attentionStates[config.id] == true {
            item.button?.contentTintColor = .systemRed
            item.button?.title = "•"
        } else {
            item.button?.contentTintColor = nil
            item.button?.title = ""
        }
    }

    private func buildStatusItem(for config: HiddenStatusItemConfig) -> NSStatusItem {
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
        return item
    }

    /// 供外部调用：当某个隐藏项有数字角标/通知时，自动展开并高亮。
    /// - Parameters:
    ///   - id: 对应 `hiddenConfigs` 的 id
    ///   - hasAttention: 是否需要高亮提示
    func markHiddenItemAttention(id: String, hasAttention: Bool) {
        attentionStates[id] = hasAttention
        // 有新提示时自动展开隐藏区（仅当该项目前未 pinned）
        if hasAttention && !isExpanded && !pinnedIds.contains(id) {
            isExpanded = true
            if let chevronItem { updateChevronIcon(on: chevronItem, animated: true) }
        }
        rebuildStatusItems()
        resetAutoCollapseTimer()
        resetIdleTimer()
    }

    @objc private func hideAllIcons() {
        // 收起所有可隐藏的图标
        if isExpanded {
            isExpanded = false
            if let chevronItem { updateChevronIcon(on: chevronItem, animated: true) }
            rebuildStatusItems()
        }
    }

    @objc private func showHiddenIcons() {
        // 展开所有隐藏的图标
        if !isExpanded {
            isExpanded = true
            if let chevronItem { updateChevronIcon(on: chevronItem, animated: true) }
            rebuildStatusItems()
        }
    }
    
    @objc private func showPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - 系统唤醒处理
    
    @objc private func handleSystemWake(_ notification: Notification) {
        // 系统唤醒后自动收起（如果启用了自动收起）
        if autoCollapseEnabled && isExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hideAllIcons()
            }
        }
    }

    private func ensureAccessibilityPermission() {
        // 请求辅助功能权限，未授权时系统会弹窗提示
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            NSLog("Awaiting accessibility permission; user will see system prompt.")
        }
    }

    // MARK: - 用户偏好：选择常驻/可隐藏

    private func makeCustomizeMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Customize Icons", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        hiddenConfigs.forEach { config in
            let sub = NSMenuItem(title: config.tooltip, action: #selector(togglePinned(_:)), keyEquivalent: "")
            sub.state = pinnedIds.contains(config.id) ? .on : .off
            sub.representedObject = config.id
            sub.target = self
            submenu.addItem(sub)
        }
        item.submenu = submenu
        return item
    }

    @objc private func togglePinned(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        let newPinned = !pinnedIds.contains(id)
        if newPinned {
            pinnedIds.insert(id)
        } else {
            pinnedIds.remove(id)
        }
        savePinnedIds(pinnedIds)
        sender.state = newPinned ? .on : .off
        rebuildStatusItems()
    }

    private func loadPinnedIds() -> Set<String> {
        let key = "BarStashPinnedIDs"
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            return Set(saved)
        }
        // 无存储时使用默认 pinned 配置
        let defaults = hiddenConfigs.filter { $0.defaultPinned }.map { $0.id }
        return Set(defaults)
    }

    private func savePinnedIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: "BarStashPinnedIDs")
    }
    
    // MARK: - 全局快捷键
    
    private func setupGlobalHotkey() {
        // 注册 ⌘+T 快捷键
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = FourCharCode(fromString: "BSts")
        hotKeyID.id = 1
        
        var eventSpec = EventTypeSpec()
        eventSpec.eventClass = UInt32(kEventClassKeyboard)
        eventSpec.eventKind = UInt32(kEventHotKeyPressed)
        
        let eventHandler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                appDelegate.toggleHiddenArea()
            }
            return noErr
        }
        
        // 使用 InstallEventHandler 替代 InstallApplicationEventHandler
        var handlerRef: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        
        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    private func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    // MARK: - 自动收起
    
    private func setupAutoCollapse() {
        if autoCollapseEnabled {
            resetAutoCollapseTimer()
        }
    }
    
    private func resetAutoCollapseTimer() {
        autoCollapseTimer?.invalidate()
        
        if autoCollapseEnabled && isExpanded {
            autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: autoCollapseDelay, repeats: false) { [weak self] _ in
                self?.hideAllIcons()
            }
        }
    }
    
    // MARK: - 空闲自动收起
    
    private func setupIdleCollapse() {
        if idleCollapseEnabled {
            resetIdleTimer()
        }
    }
    
    private func resetIdleTimer() {
        idleTimer?.invalidate()
        
        if idleCollapseEnabled && isExpanded {
            idleTimer = Timer.scheduledTimer(withTimeInterval: idleCollapseDelay, repeats: false) { [weak self] _ in
                // 检查系统是否空闲
                if let lastEvent = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown) {
                    if lastEvent > self?.idleCollapseDelay ?? 30.0 {
                        self?.hideAllIcons()
                    }
                }
            }
        }
    }
    
    private func stopTimers() {
        autoCollapseTimer?.invalidate()
        idleTimer?.invalidate()
    }
    
    // MARK: - 实验性：检测其他 App 的状态栏图标
    
    func scanOtherAppStatusItems() {
        // 实验性功能：尝试通过 Accessibility API 检测其他 App 的状态栏图标
        // 注意：此功能可能无法获取所有图标，且无法真正隐藏它们
        
        let systemWide = AXUIElementCreateSystemWide()
        var menubar: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXMenuBarAttribute as CFString,
            &menubar
        )
        
        if result == .success, let menubar = menubar {
            var children: CFTypeRef?
            let childrenResult = AXUIElementCopyAttributeValue(
                menubar as! AXUIElement,
                kAXChildrenAttribute as CFString,
                &children
            )
            
            if childrenResult == .success, let children = children as? [AXUIElement] {
                NSLog("Found \(children.count) menu bar items")
                for (index, child) in children.enumerated() {
                    var title: CFTypeRef?
                    AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &title)
                    if let title = title as? String {
                        NSLog("Menu bar item \(index): \(title)")
                    }
                }
            }
        }
    }
}

// MARK: - FourCharCode 辅助扩展

extension FourCharCode {
    init(fromString string: String) {
        precondition(string.count == 4)
        var result: FourCharCode = 0
        for char in string.utf8 {
            result = (result << 8) + FourCharCode(char)
        }
        self = result
    }
}
