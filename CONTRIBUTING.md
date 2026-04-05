# Contributing

欢迎提交改进，但请优先遵守这三个原则：

1. 不重复实现 OpenClaw 官方安装逻辑。
2. 文档必须只描述当前真实支持的能力。
3. 改动后至少验证脚本语法和 `--dry-run`。

## 提交前检查

### Bash

```bash
bash -n install
bash -n install.sh
bash test/test_all.sh
```

### PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -Help
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -DryRun -NoOnboard
```

## 不接受的改动方向

- 恢复未实现的“离线安装”宣传
- 文档和脚本行为不一致
- 引入新的仓库占位符但没有明确说明如何替换
