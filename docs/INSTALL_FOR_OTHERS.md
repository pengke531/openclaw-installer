# 给别人安装 / 卸载 OpenClaw 的步骤

## 先判断场景

### 场景 A：对方电脑有网，而且愿意复制命令

推荐在线执行。  
是否需要拷文件：不需要。

### 场景 B：你在远程桌面里协助，或者你本人就在电脑前

推荐本地单文件执行。  
是否需要拷文件：通常只需要拷一个脚本。

### 场景 C：对方电脑完全离线

当前稳定版不支持。  
原因不是脚本本身，而是 OpenClaw 官方安装链路仍需要联网下载 Node 或 npm 包。

## 远程在线安装

### Windows

让对方打开 PowerShell 执行：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

如果对方在中国大陆、GitHub Raw 不稳定，优先用：

```powershell
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/gh/pengke531/openclaw-installer@main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1" -MirrorProfile cn
```

### Linux / macOS / WSL

让对方打开终端执行：

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash
```

如果对方在中国大陆、GitHub Raw 不稳定，优先用：

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/pengke531/openclaw-installer@main/install | bash -s -- --mirror-profile cn
```

## 远程在线彻底卸载

### Windows

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-uninstall.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-uninstall.ps1" -Uninstall -PurgeData
```

### Linux / macOS / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash -s -- --uninstall --purge-data
```

## 本地单文件安装

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

## 本地单文件彻底卸载

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -Uninstall -PurgeData
```

### Linux / macOS / WSL

```bash
bash install.sh --uninstall --purge-data
```

## 什么时候需要拷文件

- 不需要：
  - 你使用在线命令
  - 目标电脑可以访问 jsDelivr / GitHub Raw 和 OpenClaw 官方地址
- 需要：
  - 你打算发一个本地脚本给对方保存后再运行
- 一般不建议拷整个仓库：
  - 对大多数用户没有必要
  - 单脚本已经足够

## 什么时候要用 git 模式

默认不需要。  
只有这些情况再用：

- 你要改 OpenClaw 源码
- 你要固定某个源码分支
- 你要做开发调试

### Windows

```powershell
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
```

### Linux / macOS / WSL

```bash
bash install.sh --install-method git --git-dir ~/openclaw
```

## 安装后要教对方做什么

现在默认情况下，安装脚本会自动生成 gateway token、刷新 gateway 服务并打开控制台，所以用户通常不用再手工处理 token。

你仍然可以让对方验证：

```bash
openclaw --version
openclaw doctor
openclaw gateway status
```

如果安装脚本没有自动做 onboarding，再执行：

```bash
openclaw onboard --install-daemon
```

然后再教他们：

1. 配置模型 API Key
2. 配置渠道
3. 打开控制台

## 卸载时要告诉对方什么

- `-Uninstall` / `--uninstall` 先卸载 CLI 与网关服务
- `-PurgeData` / `--purge-data` 会继续删状态目录、工作区和配置
- 如果是 `git` 模式安装，想连源码目录一起删，要补 `-GitDir` 或 `--git-dir`
- 脚本不会自动删掉 Node.js、Git、pnpm、bun
