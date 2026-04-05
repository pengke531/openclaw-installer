# OpenClaw 给别人安装快速参考

## 一句话判断

- 对方电脑能联网：不用拷整个项目，直接在线安装。
- 对方电脑不能联网：当前这个稳定版不适用。
- 你要现场帮装：拷一个脚本就够，不用拷整个仓库。

## Windows

在线：

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1)))
```

本地单文件：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

## Linux / macOS / WSL

在线：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

本地单文件：

```bash
bash install.sh
```

## 跳过 onboarding

```powershell
.\install-windows.ps1 -NoOnboard
```

```bash
bash install.sh --no-onboard
```

## 安装后验证

```bash
openclaw --version
openclaw doctor
openclaw gateway status
```
