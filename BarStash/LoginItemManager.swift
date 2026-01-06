import Cocoa
import ServiceManagement

class LoginItemManager {
    static let shared = LoginItemManager()
    
    private let launcherBundleID = "com.example.BarStashLauncher"
    
    private init() {}
    
    /// 检查是否已启用开机自启
    func isEnabled() -> Bool {
        guard let jobs = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]) else {
            return false
        }
        
        return jobs.contains { job in
            job["Label"] as? String == launcherBundleID
        }
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

