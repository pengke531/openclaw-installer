# OpenClaw Windows 使用说明

开发者：创造晴天  
微信：kerp531

## 适合谁

- 你本人在目标电脑前操作
- 你远程协助别人安装
- 你希望让别人复制一条 PowerShell 命令即可安装或卸载

## 前提条件

- Windows 10 / 11
- PowerShell 5+
- 目标机器可以访问：
  - `https://openclaw.ai`
  - `https://nodejs.org`
  - `https://registry.npmjs.org`
  - `https://github.com`

## 脚本会自动做什么

- 显示开发者信息
- 非 `DryRun` 模式下自动申请管理员权限
- 检查 Node.js 22+
- 检查 npm
- 检查并修正 npm 全局前缀到用户目录
- 检查并修正 npm 缓存目录到用户目录
- 检查并修正 npm / OpenClaw 所在目录到用户 PATH
- 默认直接调用 OpenClaw 官方 PowerShell 安装器
- 保留官方 `npm` / `git` 两种安装模式入口
- 支持一键卸载 OpenClaw，并可选择彻底清理状态/工作区/配置
- 安装完成后自动生成 gateway token、安装 gateway 服务并打开控制台
- 遇到旧配置或插件残留导致 OpenClaw 4.8 读配置失败时，自动备份旧配置并切换到最小本地配置

## 安装

### 方法 1：本地直接运行仓库脚本

```powershell
cd D:\claude\openclaw-installer-lite
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

### 方法 2：只发一个脚本给对方

把 [`install-windows.ps1`](/D:/claude/openclaw-installer-lite/install-windows.ps1) 发给对方，对方执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

### 方法 3：远程在线安装

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

## 常用安装变体

跳过 onboarding：

```powershell
.\install-windows.ps1 -NoOnboard
```

仅演练，不真正安装：

```powershell
.\install-windows.ps1 -DryRun -NoOnboard
```

增强诊断模式：

```powershell
.\install-windows.ps1 -VerboseInstall
```

安装完成后不自动打开控制台：

```powershell
.\install-windows.ps1 -NoDashboard
```

开发者源码模式：

```powershell
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
```

## 卸载

推荐直接使用一键彻底卸载：

```powershell
.\install-windows.ps1 -Uninstall -PurgeData
```

远程设备也可以直接执行：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1" -Uninstall -PurgeData
```

如果你只想卸载 CLI 和服务，暂时保留数据：

```powershell
.\install-windows.ps1 -Uninstall
```

如果当初是 `git` 模式安装，并且希望连源码目录一起删除：

```powershell
.\install-windows.ps1 -Uninstall -PurgeData -GitDir C:\openclaw
```

## 卸载时脚本会做什么

- 优先调用官方 `openclaw uninstall`
- 尝试停止并卸载 Gateway 服务
- 如果 `openclaw` 命令已经不存在，自动做手工清理兜底
- 清理 Windows 计划任务 `OpenClaw Gateway`
- 清理 Startup 启动项
- 清理用户状态目录里的 `gateway.cmd`
- 清理 npm 全局安装残留
- `-PurgeData` 会删除：
  - `C:\Users\<用户名>\.openclaw`
  - `C:\Users\<用户名>\.openclaw-<profile>`
  - `OPENCLAW_CONFIG_PATH` 指向的自定义配置文件
  - 你显式传入的 `-GitDir`

不会自动卸载：

- Node.js
- Git for Windows
- 其他通用依赖

## 安装完成后建议执行

```powershell
openclaw --version
openclaw doctor
openclaw gateway status
```

如果安装时跳过了 onboarding，再执行：

```powershell
openclaw onboard --install-daemon
```

## 现在安装完成后会额外自动做什么

- 运行 `openclaw doctor --repair --generate-gateway-token --yes --non-interactive`
- 确保 Gateway 服务已安装并刷新
- 自动打开 `openclaw dashboard`

这样做的目标是避免用户安装完成后，还要手工复制 token 注入网页。

如果检测到现有 `openclaw.json` 或扩展依赖会让 OpenClaw 4.8 CLI 无法读取配置，安装器会自动：

- 备份旧配置文件
- 写入最小本地配置
- 继续完成 token / gateway / dashboard 启动

## 如果安装器长时间没有新输出

先再等几分钟，因为官方安装器可能仍在下载依赖、解压 npm 包，或被杀毒软件扫描。

如果长时间没有变化，先在目标设备执行：

```powershell
node -v
npm -v
git --version
openclaw --version
```

## 常见判断

- 是否需要把整个项目拷给对方？
  - 不需要。Windows 场景通常只要发一个 `install-windows.ps1`，或者直接发 Raw 远程命令。
- 是否支持完全离线？
  - 当前不支持。
- 是否能完全零交互？
  - 不能保证。UAC 提权、管理员确认、网络策略都可能仍需人工确认。
