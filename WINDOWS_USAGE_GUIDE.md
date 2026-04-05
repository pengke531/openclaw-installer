# OpenClaw Windows 使用说明

## 适合谁

- 你本人在目标电脑前操作
- 你远程协助对方安装
- 对方愿意自己复制一条 PowerShell 命令执行

开发者：创造晴天
微信：kerp531

## 前提条件

- Windows 10/11
- PowerShell 5+
- 机器可以联网访问：
  - `https://openclaw.ai`
  - `https://nodejs.org`
  - `https://registry.npmjs.org`
  - `https://github.com`

## 脚本会自动做什么

- 显示开发者信息
- 非 DryRun 模式下，缺少管理员权限时自动请求 UAC 提权
- 检查 Git 是否存在
- 缺少 Git 时优先通过 `winget` 安装 Git for Windows
- `winget` 不可用或失败时，自动下载 Git for Windows 并静默安装
- 默认 `npm` 模式下直接执行官方推荐命令 `npm install -g openclaw@latest`
- `git` 模式下继续调用 OpenClaw 官方安装器

## 方法 1：本地直接运行仓库脚本

```powershell
cd D:\claude\openclaw-installer-lite
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

## 方法 2：只拷一个脚本到对方电脑

把 [`install-windows.ps1`](/D:/claude/openclaw-installer-lite/install-windows.ps1) 发给对方，对方执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

## 方法 3：远程在线安装

适合你不想传文件，只想让对方复制命令：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1)))
```

## 常用变体

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

开发者源码模式：

```powershell
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
```

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

## 如果卡在 `Installing OpenClaw (openclaw@latest)...`

先再等几分钟，因为这一步可能仍在下载 npm 包或被杀毒扫描。

如果长时间没有变化，先在目标设备执行：

```powershell
node -v
npm -v
npm ping
npm view openclaw version
```

如果这里正常，再执行更透明的安装命令：

```powershell
npm install -g openclaw@latest --loglevel verbose
```

## 常见判断

- 是否需要拷文件到对方电脑？
  - 不需要，如果对方直接在线执行官方或你仓库里的 Raw 命令。
  - 需要，如果你选择发一个本地脚本给对方离线保存后再运行。

- 是否要拷整个项目？
  - 不要。Windows 场景下通常只需要一个 `install-windows.ps1`。

- 是否支持完全离线？
  - 目前不支持。这个稳定版要求联网。
