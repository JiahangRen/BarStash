# 修复编译错误：多个 @main 属性

## 问题描述

错误信息：`'main' attribute can only apply to one type in a module`

这是因为 `BarStashLauncher/LauncherApp.swift` 也有 `@main` 属性，可能被错误地包含在 `BarStash` target 中。

## 解决方案

### 方案 1：在 Xcode 中排除 LauncherApp（推荐）

1. 在 Xcode 中，找到 `BarStashLauncher` 文件夹
2. 选择 `BarStashLauncher/LauncherApp.swift` 文件
3. 在右侧 File Inspector 中，查看 "Target Membership"
4. 确保 **取消勾选** `BarStash` target
5. 如果还没有 `BarStashLauncher` target，可以暂时移除这个文件的引用

### 方案 2：清理构建缓存

1. 在 Xcode 中，选择菜单：Product > Clean Build Folder (⇧⌘K)
2. 关闭 Xcode
3. 删除 Derived Data：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/BarStash-*
   ```
4. 重新打开 Xcode 项目

### 方案 3：暂时移除 LauncherApp（如果不需要开机自启功能）

1. 在 Xcode 中，右键点击 `BarStashLauncher` 文件夹
2. 选择 "Delete"
3. 选择 "Remove Reference"（不要选择 "Move to Trash"）

### 方案 4：创建独立的 Launcher Target

如果需要开机自启功能，应该创建独立的 target：

1. File > New > Target
2. 选择 macOS > App
3. 命名为 `BarStashLauncher`
4. 将 `BarStashLauncher/LauncherApp.swift` 添加到该 target
5. 确保 `BarStashLauncher` target 的 Bundle ID 为 `com.example.BarStashLauncher`

## 验证

修复后，应该只有 `BarStash/BarStashApp.swift` 有 `@main` 属性。

