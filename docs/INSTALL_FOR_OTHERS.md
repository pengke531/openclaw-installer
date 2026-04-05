# OpenClaw 为他人安装指南

## 先做选择

### 场景 A：对方电脑有网，且愿意复制命令

推荐在线安装。

是否需要拷文件：不需要。

### 场景 B：你远程桌面协助，或你本人就在电脑前

推荐本地单文件安装。

是否需要拷文件：通常只需要拷一个脚本。

### 场景 C：对方电脑完全离线

当前稳定版不支持。

原因不是脚本本身，而是 OpenClaw 官方安装链路还需要联网下载 Node 或 npm 包。

## 远程在线安装步骤

### Windows

让对方打开 PowerShell，执行：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1)))
```

### Linux / macOS / WSL

让对方打开终端，执行：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

## 本地单文件安装步骤

### Windows

1. 把 [`install-windows.ps1`](/D:/claude/openclaw-installer-lite/install-windows.ps1) 发到目标电脑。
2. 在目标电脑打开 PowerShell。
3. 执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

### Linux / macOS / WSL

1. 把 [`install.sh`](/D:/claude/openclaw-installer-lite/install.sh) 发到目标电脑。
2. 打开终端。
3. 执行：

```bash
bash install.sh
```

## 什么时候需要拷贝文件

- 不需要：
  - 你使用在线安装命令
  - 目标电脑可以直接访问 `openclaw.ai`

- 需要：
  - 你打算发一个本地包装脚本给对方
  - 对方不方便从网页复制长命令

- 不建议拷整个仓库：
  - 对大多数用户没意义
  - 单脚本已经够用

## 什么时候要用 git 模式

默认不需要。

只有这些情况再用：

- 你要改 OpenClaw 源码
- 你要锁定某个源码分支
- 你要做开发调试

### Windows

```powershell
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
```

### Linux / macOS / WSL

```bash
bash install.sh --install-method git --git-dir ~/openclaw
```

## 安装后你要教对方做什么

先验证：

```bash
openclaw --version
openclaw doctor
openclaw gateway status
```

如果安装脚本没有自动带他们做 onboarding，再执行：

```bash
openclaw onboard --install-daemon
```

然后再教他们：

1. 配置模型 API Key
2. 配置渠道
3. 打开控制台

## 发布你自己的远程入口

如果你想让别人以后都从你的 GitHub 安装：

1. 新建 GitHub 仓库
2. 上传本项目
3. 把下面命令发给别人

### Windows

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/<你的GitHub用户名>/<你的仓库名>/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

### Linux / macOS / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/<你的GitHub用户名>/<你的仓库名>/main/install.sh -o install.sh
bash install.sh
```
