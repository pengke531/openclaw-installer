# OpenClaw 安装总说明

## 项目定位

这个仓库不是 OpenClaw 官方安装器的替代品，而是一个更适合中文沟通、远程协助、单文件转发和统一卸载入口的包装层。

底层实际执行的是 OpenClaw 官方安装器或官方 CLI：

- Linux / macOS / WSL：`https://openclaw.ai/install.sh`
- Windows：`https://openclaw.ai/install.ps1`
- 卸载：优先调用 `openclaw uninstall`

## 支持矩阵

| 平台 | 在线安装 | 本地单文件 | 在线卸载 | 本地单文件卸载 | 完全离线 |
|------|----------|------------|----------|----------------|----------|
| Windows | 支持 | 支持 | 支持 | 支持 | 不支持 |
| Linux | 支持 | 支持 | 支持 | 支持 | 不支持 |
| macOS | 支持 | 支持 | 支持 | 支持 | 不支持 |
| WSL | 支持 | 支持 | 支持 | 支持 | 不支持 |

## 在线安装

### Windows

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

### Linux / macOS / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash
```

## 本地单文件安装

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

### Linux / macOS / WSL

```bash
bash install.sh
```

## 一键彻底卸载

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -Uninstall -PurgeData
```

### Linux / macOS / WSL

```bash
bash install.sh --uninstall --purge-data
```

## 常用参数

### Windows

```powershell
.\install-windows.ps1 -NoOnboard
.\install-windows.ps1 -DryRun -NoOnboard
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
.\install-windows.ps1 -Uninstall -PurgeData
```

### Linux / macOS / WSL

```bash
bash install.sh --no-onboard
bash install.sh --dry-run --no-onboard
bash install.sh --install-method git --git-dir ~/openclaw
bash install.sh --uninstall --purge-data
```

## 安装后验证

```bash
openclaw --version
openclaw doctor
openclaw gateway status
```

## 风险边界

- 目标机器必须联网
- 上游官方安装器行为未来可能变化，这个仓库会尽量少做假设
- 建议定期跑一次 `--dry-run` 自检
- 卸载不会自动删除 Node.js、Git、pnpm、bun 这类通用依赖
