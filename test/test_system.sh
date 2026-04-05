#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "install.sh 帮助输出预览："
bash "$ROOT_DIR/install.sh" --help | sed -n '1,20p'
