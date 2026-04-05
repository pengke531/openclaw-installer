# 单文件交付说明

这个项目现在支持“单文件交付”，但注意这里的单文件是“包装脚本单文件”，不是“离线安装包单文件”。

## Windows

你只需要把 [`install-windows.ps1`](/D:/claude/openclaw-installer-lite/install-windows.ps1) 发给对方。

对方执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

## Linux / macOS / WSL

你只需要把 [`install.sh`](/D:/claude/openclaw-installer-lite/install.sh) 发给对方。

对方执行：

```bash
bash install.sh
```

## 限制

- 仍然需要联网
- 仍然会下载官方安装器和依赖
- 不等于离线安装
