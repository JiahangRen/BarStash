import SwiftUI

@main
struct BarStashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // 菜单栏应用不需要窗口，使用空 Settings 场景保持激活
        Settings { EmptyView() }
    }
}

