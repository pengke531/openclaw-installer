#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== 语法检查 =="
bash -n "$ROOT_DIR/install"
bash -n "$ROOT_DIR/install.sh"

echo "== 帮助输出检查 =="
bash "$ROOT_DIR/install.sh" --help | grep -q "OpenClaw 安装包装脚本"
bash "$ROOT_DIR/install.sh" --help | grep -q -- "--uninstall"

echo "== 核心文件占位符检查 =="
TARGETS=(
    "$ROOT_DIR/README.md"
    "$ROOT_DIR/WINDOWS_USAGE_GUIDE.md"
    "$ROOT_DIR/INSTALL_FOR_OTHERS_QUICKREF.md"
    "$ROOT_DIR/SINGLE_FILE_INSTALL.md"
    "$ROOT_DIR/CONTRIBUTING.md"
    "$ROOT_DIR/install"
    "$ROOT_DIR/install.sh"
    "$ROOT_DIR/install-windows.ps1"
    "$ROOT_DIR/docs/INSTALLATION_GUIDE.md"
    "$ROOT_DIR/docs/INSTALL_FOR_OTHERS.md"
)

if grep -E "<your-username>|<username>" "${TARGETS[@]}" >/dev/null 2>&1; then
    echo "核心文件中仍存在旧占位符"
    exit 1
fi

echo "全部检查通过"
