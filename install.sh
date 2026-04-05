#!/usr/bin/env bash
set -euo pipefail

OFFICIAL_INSTALL_URL="${OPENCLAW_OFFICIAL_INSTALL_URL:-https://openclaw.ai/install.sh}"

INSTALL_METHOD=""
VERSION="latest"
GIT_DIR=""
NO_ONBOARD=0
DRY_RUN=0
VERBOSE=0
NO_PROMPT=0
USE_BETA=0

print_usage() {
    cat <<'EOF'
OpenClaw 安装包装脚本（Linux / macOS / WSL）

用途:
  这个脚本不再自己维护复杂安装逻辑，而是转调 OpenClaw 官方安装器，
  适合你本地运行、拷贝给别人运行，或作为 GitHub Raw 一键安装入口。

用法:
  bash install.sh [选项]

常用选项:
  --install-method <npm|git>  安装方式，默认 npm
  --npm                       等价于 --install-method npm
  --git                       等价于 --install-method git
  --version <tag|version>     版本，默认 latest
  --git-dir <path>            git 模式下源码目录
  --no-onboard                安装后不进入 onboarding
  --onboard                   安装后进入 onboarding
  --no-prompt                 非交互模式
  --dry-run                   只打印将执行的动作
  --verbose                   输出更详细日志
  --beta                      使用 beta 通道
  -h, --help                  显示帮助

示例:
  bash install.sh
  bash install.sh --no-onboard
  bash install.sh --install-method git --git-dir ~/openclaw
  bash install.sh --dry-run --no-onboard
EOF
}

download_to() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$output" "$url"
    else
        echo "错误：需要 curl 或 wget 来下载官方安装器。"
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install-method|--method)
            INSTALL_METHOD="${2:-}"
            shift 2
            ;;
        --npm)
            INSTALL_METHOD="npm"
            shift
            ;;
        --git|--github)
            INSTALL_METHOD="git"
            shift
            ;;
        --version)
            VERSION="${2:-}"
            shift 2
            ;;
        --git-dir|--dir)
            GIT_DIR="${2:-}"
            shift 2
            ;;
        --no-onboard)
            NO_ONBOARD=1
            shift
            ;;
        --onboard)
            NO_ONBOARD=0
            shift
            ;;
        --no-prompt|--yes)
            NO_PROMPT=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --verbose|--debug)
            VERBOSE=1
            shift
            ;;
        --beta)
            USE_BETA=1
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "错误：未知参数 $1"
            echo
            print_usage
            exit 2
            ;;
    esac
done

if [[ -n "$INSTALL_METHOD" && "$INSTALL_METHOD" != "npm" && "$INSTALL_METHOD" != "git" ]]; then
    echo "错误：--install-method 只支持 npm 或 git"
    exit 2
fi

tmp_file="$(mktemp "${TMPDIR:-/tmp}/openclaw-official-install.XXXXXX.sh")"
cleanup() {
    rm -f "$tmp_file"
}
trap cleanup EXIT

echo "正在下载 OpenClaw 官方安装器..."
download_to "$OFFICIAL_INSTALL_URL" "$tmp_file"

official_args=()
if [[ -n "$INSTALL_METHOD" ]]; then
    official_args+=(--install-method "$INSTALL_METHOD")
fi
if [[ "$USE_BETA" -eq 1 ]]; then
    official_args+=(--beta)
fi
if [[ -n "$VERSION" && "$VERSION" != "latest" ]]; then
    official_args+=(--version "$VERSION")
fi
if [[ -n "$GIT_DIR" ]]; then
    official_args+=(--git-dir "$GIT_DIR")
fi
if [[ "$NO_ONBOARD" -eq 1 ]]; then
    official_args+=(--no-onboard)
fi
if [[ "$NO_PROMPT" -eq 1 ]]; then
    official_args+=(--no-prompt)
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
    official_args+=(--dry-run)
fi
if [[ "$VERBOSE" -eq 1 ]]; then
    official_args+=(--verbose)
fi

echo "已切换到官方安装路径：$OFFICIAL_INSTALL_URL"
echo "即将执行：bash <official-installer> ${official_args[*]:-}"
echo

bash "$tmp_file" "${official_args[@]}"
