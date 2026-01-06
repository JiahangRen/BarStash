import Cocoa
import ServiceManagement

class LoginItemManager {
    static let shared = LoginItemManager()
    
    private let launcherBundleID = "com.example.BarStashLauncher"
    
    private init() {}
    
    /// 检查是否已启用开机自启
    /// 注意：由于 SMCopyAllJobDictionaries 在 macOS 10.10+ 已弃用，
    /// 我们使用 UserDefaults 来跟踪用户设置的状态
    func isEnabled() -> Bool {
        // 从 UserDefaults 读取用户设置的状态
        // 这个值在 setEnabled() 时会被更新
        return UserDefaults.standard.bool(forKey: "BarStashLoginItemEnabled")
    }
    
    /// 启用/禁用开机自启
    func setEnabled(_ enabled: Bool) -> Bool {
        let success = SMLoginItemSetEnabled(launcherBundleID as CFString, enabled)
        if success {
            UserDefaults.standard.set(enabled, forKey: "BarStashLoginItemEnabled")
        }
        return success
    }
}

