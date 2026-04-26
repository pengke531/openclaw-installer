# OpenClaw Installer v1.4.5

面向“帮别人安装或卸载 OpenClaw”的稳定包装项目。

这个仓库现在只做一件事：把 OpenClaw 的安装和卸载入口整理成稳定、可转发、可本地执行的脚本，并尽量对齐官方安装/卸载路径，而不是自己长期维护一套容易漂移的逻辑。

开发者：创造晴天  
微信：kerp531

## 当前支持

- Windows 原生安装
- Windows 原生一键卸载
- Linux / macOS / WSL 安装
- Linux / macOS / WSL 一键卸载
- 本地执行
- 远程在线执行
- `npm` 安装
- `git` 源码安装
- Windows 缺少 Node.js、npm、Git 时自动补环境
- Windows 自动修正 npm 全局前缀与 PATH
- Windows 自动修正 npm 缓存目录权限
- Bash / PowerShell 下载官方安装器时自动重试
- Windows 卸载时优先调用官方 `openclaw uninstall`，CLI 不在时自动做手工清理兜底
- 安装完成后自动生成 gateway token、安装 gateway 服务并打开 OpenClaw 控制台
- 遇到旧配置或插件残留导致 OpenClaw 4.8 读配置失败时，自动备份旧配置并切换到最小本地配置继续部署
- macOS 安装前自动检查并触发 Xcode Command Line Tools 安装

## 当前不支持

- 真正离线安装
- 自带依赖包分发
- 完全不联网完成安装

如果目标机器无法访问 `openclaw.ai`、`nodejs.org`、`registry.npmjs.org`、`github.com`，默认路径仍可能失败。

## 安装

### Windows

本地运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

远程运行你仓库里的脚本：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

### Linux / macOS / WSL

本地运行：

```bash
bash install.sh
```

远程运行你仓库里的脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash
```

macOS 额外说明：

- 如果系统首次弹出 `Xcode Command Line Tools` 安装窗口，请先完成安装。
- 安装完成后，再重新执行一次安装命令。
- 新版本脚本会在 macOS 检测到 `curl | bash` 管道启动时，自动切换到本地临时脚本模式，尽量恢复正常交互终端。
- 如果客户机器上已有旧版 Node.js / npm 且全局目录在 `/usr/local`，新版本会优先切换到用户级 npm 目录，避免 `EACCES: permission denied`。
- 如果客户机器仍然对 `curl | bash` 的交互处理不稳定，改用下面这个更稳的两步命令：

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh -o /tmp/openclaw-install.sh
bash /tmp/openclaw-install.sh
```

目前更推荐直接使用 `install.sh` 本体，而不是仓库入口 `install`。
原因：GitHub CDN 缓存刷新可能有延迟，直连 `install.sh` 更稳定。

## 卸载

### Windows 一键彻底卸载

本地运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -Uninstall -PurgeData
```

远程运行：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1" -Uninstall -PurgeData
```

### Linux / macOS / WSL 一键彻底卸载

本地运行：

```bash
bash install.sh --uninstall --purge-data
```

远程运行：

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash -s -- --uninstall --purge-data
```

## 常用参数

### Bash

```bash
bash install.sh --no-onboard
bash install.sh --no-dashboard
bash install.sh --install-method git --git-dir ~/openclaw
bash install.sh --dry-run --no-onboard
bash install.sh --uninstall --purge-data
```

### PowerShell

```powershell
.\install-windows.ps1 -NoOnboard
.\install-windows.ps1 -NoDashboard
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
.\install-windows.ps1 -VerboseInstall
.\install-windows.ps1 -DryRun -NoOnboard
.\install-windows.ps1 -Uninstall -PurgeData
```

## 首装闭环

默认安装完成后，脚本还会继续完成一轮首次启动 bootstrap：

- 修正 npm 全局前缀、缓存目录与 PATH
- 执行 `openclaw doctor --repair --generate-gateway-token --yes --non-interactive`
- 安装并刷新 Gateway 服务
- 自动打开 `openclaw dashboard`

这样做的目标是让用户安装完就能直接进入 OpenClaw 控制台，不再手工处理 gateway token。

如果检测到现有配置、旧插件残留或渠道扩展依赖会导致 OpenClaw 4.8 CLI 读配置失败，安装器会自动：

- 备份旧 `openclaw.json`
- 写入一份最小本地配置
- 用最小配置继续完成 token、gateway、dashboard 首装闭环

如果你只想完成安装、不自动打开控制台：

```powershell
.\install-windows.ps1 -NoDashboard
```

```bash
bash install.sh --no-dashboard
```

## 卸载说明

- `-Uninstall` / `--uninstall`：卸载 OpenClaw CLI 与 Gateway 服务
- `-PurgeData` / `--purge-data`：额外删除状态目录、工作区、配置和显式传入的 git 源码目录
- Windows 会优先调用官方 `openclaw uninstall`
- 如果 `openclaw` 命令已经不存在，脚本会自动尝试清理计划任务、Startup 启动项、`gateway.cmd`、npm 全局残留
- 脚本不会自动卸载 `Node.js`、`Git`、`pnpm`、`bun` 这类通用依赖

## 使用建议

- 普通用户安装：默认 `npm` 模式
- 开发者或要改源码：`git` 模式
- 远程协助：优先让对方直接执行 Raw 命令，不必先发整个仓库
- 彻底卸载：直接使用 `-Uninstall -PurgeData` 或 `--uninstall --purge-data`
- 如果当初是 `git` 模式安装，卸载时加上 `-GitDir <路径>` 或 `--git-dir <path>`，这样能顺带删掉源码目录

## 文档

- [Windows 使用说明](./WINDOWS_USAGE_GUIDE.md)
- [快速参考卡](./INSTALL_FOR_OTHERS_QUICKREF.md)
- [安装总说明](./docs/INSTALLATION_GUIDE.md)
- [给别人安装的步骤](./docs/INSTALL_FOR_OTHERS.md)

## 设计原则

1. 优先复用官方安装器和官方卸载器，减少上游变动带来的维护成本。
2. 对外暴露少量稳定参数，让普通用户更容易执行。
3. 安装与卸载都支持本地和远程两种分发方式。
4. 文档只写当前真实支持的路径，不虚构离线能力。
