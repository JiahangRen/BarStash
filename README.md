# BarStash

macOS 菜单栏应用，提供状态栏快捷入口与隐藏/显示图标的操作示例。

## 功能
- 状态栏图标使用 SF Symbol `statusbar.text`。
- 菜单项：`Hide All Icons`、`Show Hidden Icons`、`Quit BarStash`。
- 启动时检查辅助功能（Accessibility）权限，未授权会触发系统提示。
- 提供 HiddenBar 风格的隐藏区：新增箭头图标，默认收起隐藏图标；点击箭头展开，再次点击收起（示例隐藏图标为占位，可替换为真实业务图标）。
- 支持自定义常驻/可隐藏图标：在主菜单 `Customize Icons` 勾选为常驻（收起也显示），未勾选则可被箭头收起；偏好会持久化。
- 通知高亮：调用 `markHiddenItemAttention(id:hasAttention:)`，未常驻的项在有提示时会自动展开并以红色点高亮。
- 系统限制说明：macOS 允许 ⌘ + 拖动重新排列状态栏项，但只能管理“本 App 创建的” `NSStatusItem`，无法主动隐藏或显示其他 App 的图标。

## 项目结构
- `BarStash.xcodeproj`：Xcode 工程。
- `BarStash/BarStashApp.swift`：SwiftUI 入口，保持无窗口菜单栏模式。
- `BarStash/AppDelegate.swift`：状态栏图标、菜单逻辑与辅助功能权限检查。
- `BarStash/Info.plist`：基础配置，`LSUIElement` 设为 `true` 以隐藏 Dock 图标。
- `BarStash/Assets.xcassets`：资源目录，含占位 App 图标集。

## 构建与运行
1) 在 Xcode 打开 `BarStash.xcodeproj`。  
2) 在 Targets > Signing & Capabilities 配置有效的 Team 与唯一的 Bundle ID（默认 `com.example.BarStash`）。  
3) 选择目标 `BarStash`，运行（macOS 13.0+）。  
4) 首次启动会弹出辅助功能权限提示，请在「系统设置 > 隐私与安全性 > 辅助功能」勾选 BarStash。

## 使用
- 点击状态栏图标展开菜单。  
- 点击箭头（chevron）展开/收起隐藏区，示例里会动态添加/移除隐藏图标。  
- `Hide All Icons` / `Show Hidden Icons` 目前为占位逻辑（`NSLog` 输出），可按需接入实际隐藏/恢复实现。  
- `Quit BarStash` 退出应用。
- `Customize Icons` 子菜单：勾选即常驻外显；未勾选则随箭头收起/展开。偏好会被记忆。
- ⌘ + 拖动可在系统层面调整各状态栏图标顺序，但仅限已显示的项，且无法借此隐藏/显示其他 App 的图标。

## 后续可做
- 补充实际的图标隐藏/恢复逻辑。  
- 添加真实 App 图标资源。  
- 增加快捷键或偏好设置界面。

