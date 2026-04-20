# OpenClaw 安装 / 卸载快速参考

开发者：创造晴天  
微信：kerp531

## Windows 安装

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-install.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-install.ps1"
```

## Windows 一键彻底卸载

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install-windows.ps1" -OutFile "$env:TEMP\openclaw-uninstall.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\openclaw-uninstall.ps1" -Uninstall -PurgeData
```

## Linux / macOS / WSL 安装

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash
```

## Linux / macOS / WSL 一键彻底卸载

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash -s -- --uninstall --purge-data
```

## 常用变体

Windows 跳过 onboarding：

```powershell
.\install-windows.ps1 -NoOnboard
```

Windows DryRun：

```powershell
.\install-windows.ps1 -DryRun -NoOnboard
```

Windows git 模式：

```powershell
.\install-windows.ps1 -InstallMethod git -GitDir C:\openclaw
```

Linux / macOS / WSL 跳过 onboarding：

```bash
bash install.sh --no-onboard
```

Linux / macOS / WSL git 模式：

```bash
bash install.sh --install-method git --git-dir ~/openclaw
```
