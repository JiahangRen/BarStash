import Cocoa

@main
class LauncherApp: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查主应用是否已在运行
        let mainAppIdentifier = "com.example.BarStash"
        let runningApps = NSWorkspace.shared.runningApplications
        
        let isRunning = runningApps.contains { app in
            app.bundleIdentifier == mainAppIdentifier
        }
        
        if !isRunning {
            // 启动主应用
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast() // 移除 Launcher.app
            components.removeLast() // 移除 Contents
            components.append("MacOS")
            components.append("BarStash")
            
            let mainAppPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(mainAppPath)
        }
        
        // 退出 Launcher
        NSApp.terminate(nil)
    }
}

