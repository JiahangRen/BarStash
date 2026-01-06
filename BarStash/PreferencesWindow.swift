import SwiftUI

struct PreferencesView: View {
    @AppStorage("BarStashAutoCollapseEnabled") private var autoCollapseEnabled = false
    @AppStorage("BarStashAutoCollapseDelay") private var autoCollapseDelay = 5.0
    @AppStorage("BarStashIdleCollapseEnabled") private var idleCollapseEnabled = false
    @AppStorage("BarStashIdleCollapseDelay") private var idleCollapseDelay = 30.0
    @State private var loginItemEnabled = LoginItemManager.shared.isEnabled()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("BarStash Preferences")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Divider()
                
                // 开机自启设置
                Toggle("Launch at login", isOn: Binding(
                    get: { loginItemEnabled },
                    set: { newValue in
                        loginItemEnabled = LoginItemManager.shared.setEnabled(newValue)
                    }
                ))
                .font(.headline)
                
                Divider()
                
                // 自动收起设置
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Auto-collapse after delay", isOn: $autoCollapseEnabled)
                        .font(.headline)
                    
                    if autoCollapseEnabled {
                        HStack {
                            Text("Delay:")
                            Slider(value: $autoCollapseDelay, in: 1...60, step: 1)
                            Text("\(Int(autoCollapseDelay))s")
                                .frame(width: 40)
                        }
                        .padding(.leading, 20)
                    }
                }
                
                Divider()
                
                // 空闲自动收起设置
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Auto-collapse when idle", isOn: $idleCollapseEnabled)
                        .font(.headline)
                    
                    if idleCollapseEnabled {
                        HStack {
                            Text("Idle time:")
                            Slider(value: $idleCollapseDelay, in: 10...300, step: 10)
                            Text("\(Int(idleCollapseDelay))s")
                                .frame(width: 50)
                        }
                        .padding(.leading, 20)
                    }
                }
                
                Divider()
                
                // 快捷键提示
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keyboard Shortcut")
                        .font(.headline)
                    Text("⌘ + T: Toggle hidden icons")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 400, height: 350)
    }
}

class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()
    
    private var preferencesWindow: NSWindow?
    
    private init() {
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "BarStash Preferences"
            window.center()
            window.isReleasedWhenClosed = false
            
            // 创建 SwiftUI 视图并设置到窗口
            let hostingView = NSHostingView(rootView: PreferencesView())
            hostingView.frame = window.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 400, height: 350)
            hostingView.autoresizingMask = [.width, .height]
            
            window.contentView = hostingView
            preferencesWindow = window
            self.window = window
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

