# OpenClaw 安装说明

## 项目定位

这个仓库不是 OpenClaw 官方安装器的替代品，而是一个更适合中文沟通、远程协助和单文件转发的包装层。

底层实际执行的是 OpenClaw 官方安装器：

- Linux / macOS / WSL: `https://openclaw.ai/install.sh`
- Windows: `https://openclaw.ai/install.ps1`

## 支持矩阵

| 平台 | 在线安装 | 本地单文件 | 完全离线 |
|------|----------|------------|----------|
| Windows | 支持 | 支持 | 不支持 |
| Linux | 支持 | 支持 | 不支持 |
| macOS | 支持 | 支持 | 不支持 |
| WSL | 支持 | 支持 | 不支持 |

## 在线安装

### Windows

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1)))
```

### Linux / macOS / WSL

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
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

## 常用参数

### Windows

```powershell
.\install-windows.ps1 -NoOnboard
.\install-windows.ps1 -DryRun
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
```

### Linux / macOS / WSL

```bash
bash install.sh --no-onboard
bash install.sh --dry-run
bash install.sh --install-method git --git-dir ~/openclaw
```

## 安装后验证

```bash
openclaw --version
openclaw doctor
openclaw gateway status
```

## 风险边界

- 目标机器必须联网
- 官方安装器行为未来可能变化，但这个包装层会尽量少做假设
- 如果你要长期对外分发，建议定期跑一遍 `--dry-run` 验证
