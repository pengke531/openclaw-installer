# OpenClaw 安装 / 卸载快速参考

开发者：AI创世纪  
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

## Linux / WSL 安装

```bash
curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh | bash
```

## macOS 安装

推荐直接发这条“两步带进度版”：

```bash
curl -fL --connect-timeout 15 --max-time 600 --retry 3 --retry-delay 2 \
  https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh \
  -o /tmp/openclaw-install.sh && bash /tmp/openclaw-install.sh
```

说明：

- 如果按回车后一直没反应，通常是 GitHub Raw 下载阶段网络慢，不是脚本已经执行失败。
- 两步命令能看见下载进度，更容易判断问题是在网络还是在安装过程。

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
