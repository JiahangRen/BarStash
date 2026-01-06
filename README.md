# BarStash

macOS 菜单栏应用，类似 HiddenBar、Bartender、Ice，提供状态栏图标管理功能，保持菜单栏整洁。

## 核心功能

### 基础功能
- **状态栏图标**：使用 SF Symbol `statusbar.text` 作为主入口
- **隐藏区管理**：类似 HiddenBar 的箭头控制，可展开/收起隐藏的图标
- **自定义常驻/隐藏**：通过菜单或偏好设置选择哪些图标常驻显示，哪些可被收起
- **通知高亮**：当隐藏图标有通知时自动展开并高亮显示

### 高级功能
- **全局快捷键**：⌘ + T 快速切换隐藏区展开/收起
- **自动收起**：可设置延迟时间，展开后自动收起
- **空闲自动收起**：检测系统空闲时间，自动收起隐藏区
- **开机自启**：支持通过 Launcher 应用实现开机自启动
- **偏好设置窗口**：SwiftUI 图形界面配置所有选项
- **视觉动画**：展开/收起时的淡入淡出动画效果

### 实验性功能
- **检测其他 App 图标**：通过 Accessibility API 尝试检测其他应用的状态栏图标（功能有限，无法真正隐藏）

## 项目结构

```
BarStash/
├── BarStashApp.swift          # SwiftUI 应用入口
├── AppDelegate.swift          # 主逻辑：状态栏、菜单、快捷键、定时器
├── PreferencesWindow.swift     # 偏好设置窗口（SwiftUI）
├── LoginItemManager.swift      # 开机自启管理
├── Info.plist                 # 应用配置
└── Assets.xcassets/           # 资源文件

BarStashLauncher/
└── LauncherApp.swift          # 开机自启辅助应用
```

## 构建与运行

### 前置要求
- macOS 13.0+
- Xcode 14.0+
- 有效的 Apple Developer 账号（用于代码签名）

### 构建步骤

1. **打开项目**
   ```bash
   open BarStash.xcodeproj
   ```

2. **添加新文件到项目**
   - 在 Xcode 中右键点击 `BarStash` 文件夹
   - 选择 "Add Files to BarStash..."
   - 添加以下文件：
     - `PreferencesWindow.swift`
     - `LoginItemManager.swift`
   - 确保 "Copy items if needed" 已勾选
   - Target Membership 勾选 `BarStash`

3. **配置签名**
   - 选择 Target `BarStash`
   - 在 Signing & Capabilities 中：
     - 选择你的 Team
     - 设置唯一的 Bundle ID（如 `com.yourname.BarStash`）
   - 更新 `Info.plist` 中的 Bundle Identifier

4. **配置 Launcher（可选，用于开机自启）**
   - 创建新的 Target：File > New > Target > macOS > App
   - 命名为 `BarStashLauncher`
   - Bundle ID 设置为 `com.yourname.BarStashLauncher`
   - 添加 `BarStashLauncher/LauncherApp.swift` 到该 Target
   - 在 `BarStash` Target 的 Build Phases 中添加 Launcher 作为依赖

5. **权限设置**
   - 首次运行会提示辅助功能权限
   - 前往「系统设置 > 隐私与安全性 > 辅助功能」勾选 BarStash

## 使用说明

### 基本操作

1. **展开/收起隐藏区**
   - 点击状态栏的箭头图标
   - 或使用快捷键 ⌘ + T

2. **自定义图标显示**
   - 点击主图标打开菜单
   - 选择 "Customize Icons" 子菜单
   - 勾选/取消勾选图标以设置常驻或可隐藏

3. **偏好设置**
   - 菜单 > Preferences...（⌘ + ,）
   - 或点击主图标 > Preferences...

### 偏好设置选项

- **Launch at login**：开机自启动
- **Auto-collapse after delay**：延迟自动收起（1-60 秒）
- **Auto-collapse when idle**：空闲自动收起（10-300 秒）

### 快捷键

- **⌘ + T**：切换隐藏区展开/收起
- **⌘ + ,**：打开偏好设置
- **⌘ + Q**：退出应用

## 技术实现

### 状态栏管理
- 使用 `NSStatusItem` 创建和管理状态栏图标
- 通过动态添加/移除 `NSStatusItem` 实现隐藏效果
- 仅能管理本应用创建的图标，无法控制其他应用的图标

### 全局快捷键
- 使用 Carbon API (`RegisterEventHotKey`) 注册全局快捷键
- 支持应用在后台时响应快捷键

### 自动收起
- 使用 `Timer` 实现延迟自动收起
- 通过 `CGEventSource.secondsSinceLastEventType` 检测系统空闲时间

### 开机自启
- 使用 `SMLoginItemSetEnabled` API
- 通过独立的 Launcher 应用实现（避免 Dock 图标显示）

### 实验性：检测其他 App 图标
- 通过 Accessibility API (`AXUIElement`) 尝试读取菜单栏元素
- **限制**：只能读取部分可访问的元素，无法真正隐藏其他应用的图标
- 调用 `scanOtherAppStatusItems()` 方法查看日志输出

## 已知限制

1. **无法隐藏其他 App 的图标**
   - macOS 公共 API 不允许控制其他应用的状态栏图标
   - 只能管理本应用创建的 `NSStatusItem`
   - 这是系统安全限制，所有类似应用（HiddenBar、Bartender）都遵循此限制

2. **辅助功能权限**
   - 需要用户手动授予辅助功能权限
   - 某些功能（如检测其他图标）需要此权限

3. **开机自启**
   - 需要独立的 Launcher 应用
   - 首次启用可能需要在系统设置中手动确认

## 开发计划

- [ ] 支持更多自定义图标配置
- [ ] 添加图标分组功能
- [ ] 支持自定义快捷键
- [ ] 添加更多动画效果
- [ ] 支持主题切换
- [ ] 探索更高级的图标检测方法（实验性）

## 参考项目

- [HiddenBar](https://github.com/dwarvesf/hidden) - 轻量级菜单栏隐藏工具
- [Bartender](https://www.macbartender.com/) - 功能强大的菜单栏管理工具
- [Ice](https://github.com/jordanbaird/Ice) - 现代化的菜单栏管理工具

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
