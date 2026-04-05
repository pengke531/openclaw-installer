# OpenClaw Installer v1.0.0

一个面向“帮别人安装 OpenClaw”的正式可交付包装项目。

这个仓库现在只做一件事：把安装入口收敛成稳定、可转发、可本地执行的脚本，底层统一调用 OpenClaw 官方安装器，而不是自己维护一套容易漂移的安装逻辑。

开发者：创造晴天
微信：kerp531

## 当前支持范围

- Windows 原生安装
- Linux / macOS / WSL 安装
- 本地执行
- 远程在线执行
- 从源码 `git` 安装或默认 `npm` 安装
- Windows 缺少 Git 时自动补装 Git for Windows
- Windows 实际安装时自动请求管理员权限

## 当前不支持

- 真正离线安装
- 自带依赖包分发
- 不联网完成安装

如果目标机器无法访问 `openclaw.ai`、`nodejs.org`、npm registry 或 GitHub，这个项目不适合直接使用。

## 当前版本结论

- Windows：已针对“用户名/路径异常导致 Git 自举失败”做补强
- Linux / macOS / WSL：未发现与本次 Windows 问题同类的 Git 自举缺陷
- 仍然依赖官方安装器的网络可用性和上游行为

## 推荐用法

### Windows

本地文件运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

远程在线运行：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1)))
```

如果你要通过自己的 GitHub 仓库转发：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/<你的GitHub用户名>/<你的仓库名>/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

### Linux / macOS / WSL

本地文件运行：

```bash
bash install.sh
```

远程在线运行官方安装器：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

如果你要通过自己的 GitHub 仓库转发：

```bash
curl -fsSL https://raw.githubusercontent.com/<你的GitHub用户名>/<你的仓库名>/main/install.sh -o install.sh
bash install.sh
```

## 常用参数

### Bash

```bash
bash install.sh --no-onboard
bash install.sh --install-method git --git-dir ~/openclaw
bash install.sh --dry-run --no-onboard
```

### PowerShell

```powershell
.\install-windows.ps1 -NoOnboard
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
.\install-windows.ps1 -DryRun -NoOnboard
```

## 使用建议

- 普通用户安装：默认 `npm` 模式
- 开发者或要改源码：`git` 模式
- 远程协助：优先让对方在线执行，不要先拷整个仓库
- 本地交付：只需拷单个脚本，不必拷整个项目

## 文档

- [Windows 使用说明](./WINDOWS_USAGE_GUIDE.md)
- [给别人安装的步骤](./docs/INSTALL_FOR_OTHERS.md)
- [快速参考卡](./INSTALL_FOR_OTHERS_QUICKREF.md)
- [单文件交付方式](./SINGLE_FILE_INSTALL.md)

## 设计原则

1. 官方安装逻辑优先，避免本仓库和上游行为漂移。
2. 对外只暴露少量稳定参数。
3. 文档只写当前真实支持的路径，不再保留未落地的离线能力描述。
