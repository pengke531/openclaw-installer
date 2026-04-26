#!/usr/bin/env bash
set -euo pipefail

RELEASE_VERSION="1.4.3"
UNAME_S="$(uname -s)"
DEFAULT_OFFICIAL_INSTALL_URL="https://openclaw.ai/install.sh"
OFFICIAL_INSTALL_URL="${OPENCLAW_OFFICIAL_INSTALL_URL:-$DEFAULT_OFFICIAL_INSTALL_URL}"
DEFAULT_OPENCLAW_VERSION="latest"

INSTALL_METHOD=""
VERSION="$DEFAULT_OPENCLAW_VERSION"
GIT_DIR=""
UNINSTALL=0
PURGE_DATA=0
NO_ONBOARD=0
NO_DASHBOARD=0
DRY_RUN=0
VERBOSE=0
NO_PROMPT=0
USE_BETA=0

print_usage() {
    cat <<'EOF'
OpenClaw 安装包装脚本（Linux / macOS / WSL）

用途：
  这个脚本不再自己维护复杂安装逻辑，而是转调 OpenClaw 官方安装器，
  同时补充一键卸载入口，适合本地执行、发给别人执行，或作为 GitHub Raw 命令入口。

用法：
  bash install.sh [选项]

常用选项：
  --install-method <npm|git>  安装方式，默认 npm
  --npm                       等价于 --install-method npm
  --git                       等价于 --install-method git
  --version <tag|version>     版本，默认 latest
  --git-dir <path>            git 模式源码目录
  --official-installer-url <url>
                              覆盖官方安装器地址
  --uninstall                 一键卸载 OpenClaw CLI 与服务
  --purge-data                与 --uninstall 搭配，额外删除状态/工作区/配置
  --no-onboard                安装后不进入 onboarding
  --onboard                   安装后进入 onboarding
  --no-dashboard              安装完成后不自动打开 OpenClaw 控制台
  --no-prompt                 非交互模式
  --dry-run                   只打印将执行的动作
  --verbose                   输出更详细日志
  --beta                      使用 beta 通道
  -h, --help                  显示帮助

示例：
  bash install.sh
  bash install.sh --no-onboard
  bash install.sh --no-dashboard
  bash install.sh --install-method git --git-dir ~/openclaw
  bash install.sh --uninstall --purge-data
  bash install.sh --dry-run --no-onboard
EOF
}

print_banner() {
    cat <<EOF
============================================================
OpenClaw 一键安装工具 v${RELEASE_VERSION}
开发者：创造晴天 / 微信：kerp531
============================================================

EOF
}

download_once() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fL --proto '=https' --tlsv1.2 \
            --connect-timeout 15 --max-time 600 \
            --retry 3 --retry-delay 2 --retry-all-errors \
            -o "$output" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$output" --timeout=15 --tries=4 "$url"
    else
        echo "错误：需要 curl 或 wget 来下载官方安装器。"
        exit 1
    fi
}

download_to() {
    local output="$1"
    shift
    local urls=("$@")
    local url=""

    for url in "${urls[@]}"; do
        [[ -n "$url" ]] || continue
        echo "尝试下载：$url"
        if download_once "$url" "$output"; then
            DOWNLOADED_FROM_URL="$url"
            return 0
        fi
        echo "下载失败，准备尝试下一个源。"
    done

    echo "错误：所有安装器下载源都失败了。"
    return 1
}

build_official_installer_candidates() {
    local candidates=()
    candidates+=("$OFFICIAL_INSTALL_URL")
    printf '%s\n' "${candidates[@]}"
}

ensure_macos_prereqs() {
    if [[ "$UNAME_S" != "Darwin" ]]; then
        return 0
    fi

    if xcode-select -p >/dev/null 2>&1; then
        if command -v git >/dev/null 2>&1; then
            return 0
        fi
        echo "检测到 Xcode Command Line Tools 路径存在，但 git 仍不可用。请先完成 Command Line Tools 安装后重新执行。"
        exit 11
    fi

    echo "检测到 macOS 尚未安装 Xcode Command Line Tools，正在尝试触发系统安装..."
    echo "如果系统弹出安装窗口，请点击安装并等待完成。安装完成后，请重新执行本脚本。"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DryRun] xcode-select --install"
        return 0
    fi

    xcode-select --install >/dev/null 2>&1 || true
    echo "已触发 Xcode Command Line Tools 安装。请先完成安装，再重新执行 OpenClaw 一键安装命令。"
    exit 10
}

invoke_official_installer() {
    local script_path="$1"
    shift

    if [[ "$UNAME_S" == "Darwin" && "$NO_PROMPT" -eq 0 ]]; then
        if [[ -t 0 ]]; then
            bash "$script_path" "$@"
            return
        fi

        if command -v script >/dev/null 2>&1 && [[ -r /dev/tty ]]; then
            script -q /dev/null bash "$script_path" "$@" < /dev/tty
            return
        fi

        if [[ -r /dev/tty ]]; then
            bash "$script_path" "$@" < /dev/tty
            return
        fi

        echo "错误：当前 macOS 会话无法提供交互终端，官方安装器无法安全输入 sudo 密码。"
        echo "请改用“先下载脚本，再本地执行”的方式重新安装："
        echo "  curl -fsSL https://raw.githubusercontent.com/pengke531/openclaw-installer/main/install.sh -o /tmp/openclaw-install.sh"
        echo "  bash /tmp/openclaw-install.sh"
        exit 12
    fi

    bash "$script_path" "$@"
}

run_or_echo() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DryRun] $*"
        return 0
    fi
    "$@"
}

get_default_openclaw_state_dir() {
    if [[ -n "${OPENCLAW_STATE_DIR:-}" ]]; then
        printf '%s\n' "$OPENCLAW_STATE_DIR"
        return 0
    fi
    printf '%s\n' "$HOME/.openclaw"
}

new_bootstrap_token() {
    node -e "const crypto=require('crypto'); process.stdout.write(crypto.randomBytes(24).toString('hex'))"
}

get_openclaw_config_path() {
    if command -v openclaw >/dev/null 2>&1; then
        local cfg_path
        cfg_path="$(openclaw config file 2>/dev/null || true)"
        if [[ -n "$cfg_path" ]]; then
            printf '%s\n' "$cfg_path"
            return 0
        fi
    fi

    if [[ -n "${OPENCLAW_CONFIG_PATH:-}" ]]; then
        printf '%s\n' "$OPENCLAW_CONFIG_PATH"
        return 0
    fi

    printf '%s\n' "$HOME/.openclaw/openclaw.json"
}

backup_openclaw_config() {
    local config_path="$1"
    if [[ -z "$config_path" || ! -f "$config_path" ]]; then
        return 0
    fi
    local backup_path="${config_path}.installer-backup-$(date +%Y%m%d-%H%M%S).json"
    cp "$config_path" "$backup_path"
    printf '%s\n' "$backup_path"
}

write_minimal_openclaw_config() {
    local config_path="$1"
    local token="$2"
    local config_dir
    config_dir="$(dirname "$config_path")"
    local state_dir
    state_dir="$(get_default_openclaw_state_dir)"

    mkdir -p "$config_dir"
    mkdir -p "$state_dir"

    node - <<'NODE' "$config_path" "$token"
const fs = require('fs');
const path = process.argv[2];
const token = process.argv[3];
const payload = {
  gateway: {
    mode: 'local',
    bind: 'loopback',
    auth: { mode: 'token', token },
    trustedProxies: ['127.0.0.1', '::1']
  },
  meta: {
    lastTouchedAt: new Date().toISOString(),
    lastTouchedVersion: 'installer-bootstrap'
  }
};
fs.writeFileSync(path, JSON.stringify(payload, null, 2));
NODE
}

test_openclaw_config_healthy() {
    if ! command -v openclaw >/dev/null 2>&1; then
        return 1
    fi

    local output
    output="$(openclaw dashboard --no-open 2>&1 || true)"
    if printf '%s' "$output" | grep -Eq 'Failed to read config|MODULE_NOT_FOUND|Cannot find module'; then
        return 1
    fi
    return 0
}

ensure_openclaw_bootstrap_config() {
    local config_path
    config_path="$(get_openclaw_config_path)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DryRun] 检查 OpenClaw 配置健康状态；若发现 4.8 配置或扩展冲突，将自动备份并写入最小本地配置"
        return 0
    fi

    if [[ -f "$config_path" ]]; then
        if test_openclaw_config_healthy; then
            echo "OpenClaw 现有配置读取正常，继续使用当前配置。"
            return 0
        fi

        local backup_path
        backup_path="$(backup_openclaw_config "$config_path")"
        if [[ -n "$backup_path" ]]; then
            echo "检测到现有配置可能与当前 OpenClaw 版本不兼容，已自动备份到：$backup_path"
        fi
    else
        echo "未发现可用的 OpenClaw 配置，将创建一份最小本地配置。"
    fi

    local bootstrap_token
    bootstrap_token="$(new_bootstrap_token)"
    write_minimal_openclaw_config "$config_path" "$bootstrap_token"
    echo "已写入最小 OpenClaw 本地配置，用于完成首次启动。"
}

get_gateway_token_from_config() {
    local config_path
    config_path="$(get_openclaw_config_path)"
    if [[ ! -f "$config_path" ]]; then
        return 0
    fi

    node -e "const fs=require('fs'); try { const data=JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); const token=(((data.gateway||{}).auth||{}).token); if (typeof token==='string') process.stdout.write(token); } catch {}" "$config_path"
}

collect_state_dirs() {
    local dirs=()

    if [[ -n "${OPENCLAW_STATE_DIR:-}" ]]; then
        dirs+=("$OPENCLAW_STATE_DIR")
    fi

    dirs+=("$HOME/.openclaw")

    while IFS= read -r dir; do
        [[ -n "$dir" ]] && dirs+=("$dir")
    done < <(find "$HOME" -maxdepth 1 -type d -name '.openclaw-*' 2>/dev/null | sort)

    if [[ ${#dirs[@]} -gt 0 ]]; then
        printf '%s\n' "${dirs[@]}" | awk 'NF && !seen[$0]++'
    fi
}

remove_path_if_exists() {
    local target="$1"
    if [[ -z "$target" ]]; then
        return 0
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DryRun] rm -rf $target"
        return 0
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        rm -rf "$target"
        echo "已删除：$target"
    fi
}

uninstall_openclaw() {
    echo "开始执行 OpenClaw 卸载流程..."

    if command -v openclaw >/dev/null 2>&1; then
        if [[ "$PURGE_DATA" -eq 1 ]]; then
            run_or_echo openclaw uninstall --all --yes --non-interactive || true
        else
            run_or_echo openclaw uninstall --service --yes --non-interactive || true
        fi
        run_or_echo openclaw gateway stop || true
        run_or_echo openclaw gateway uninstall || true
    else
        echo "未检测到 openclaw 命令，直接执行手工清理兜底。"
    fi

    case "$(uname -s)" in
        Darwin*)
            while IFS= read -r agent; do
                [[ -n "$agent" ]] || continue
                label="$(basename "$agent" .plist)"
                run_or_echo launchctl bootout "gui/$UID/$label" || true
                remove_path_if_exists "$agent"
            done < <(find "$HOME/Library/LaunchAgents" -maxdepth 1 -type f \( -name 'ai.openclaw*.plist' -o -name 'com.openclaw*.plist' \) 2>/dev/null | sort)
            ;;
        Linux*)
            if command -v systemctl >/dev/null 2>&1; then
                while IFS= read -r unit; do
                    [[ -n "$unit" ]] || continue
                    name="$(basename "$unit")"
                    run_or_echo systemctl --user disable --now "$name" || true
                    remove_path_if_exists "$unit"
                done < <(find "$HOME/.config/systemd/user" -maxdepth 1 -type f -name 'openclaw-gateway*.service' 2>/dev/null | sort)
                run_or_echo systemctl --user daemon-reload || true
            fi
            ;;
    esac

    if command -v npm >/dev/null 2>&1; then
        run_or_echo npm rm -g openclaw --loglevel error || true
        npm_prefix="$(npm config get prefix 2>/dev/null || true)"
        remove_path_if_exists "${npm_prefix}/bin/openclaw"
        remove_path_if_exists "${npm_prefix}/openclaw"
    fi
    if command -v pnpm >/dev/null 2>&1; then
        run_or_echo pnpm remove -g openclaw || true
    fi
    if command -v bun >/dev/null 2>&1; then
        run_or_echo bun remove -g openclaw || true
    fi

    remove_path_if_exists "$HOME/.local/bin/openclaw"

    if [[ "$PURGE_DATA" -eq 1 ]]; then
        while IFS= read -r state_dir; do
            remove_path_if_exists "$state_dir"
        done < <(collect_state_dirs)

        if [[ -n "${OPENCLAW_CONFIG_PATH:-}" ]]; then
            remove_path_if_exists "$OPENCLAW_CONFIG_PATH"
        fi
        if [[ -n "$GIT_DIR" ]]; then
            remove_path_if_exists "$GIT_DIR"
        fi
    else
        echo "未指定 --purge-data，保留 OpenClaw 状态、工作区和配置数据。"
        if [[ -n "$GIT_DIR" ]]; then
            echo "已保留 git 源码目录；如需一并删除，请与 --uninstall 搭配 --purge-data --git-dir <path>。"
        fi
    fi

    echo "OpenClaw 卸载流程已执行完成。"
    echo "Node.js、Git、pnpm、bun 属于通用依赖，本脚本不会自动卸载它们。"
}

bootstrap_first_launch() {
    echo "正在执行 OpenClaw 首次启动自检..."

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DryRun] 检查 OpenClaw 配置健康状态；必要时备份旧配置并写入最小本地配置"
        echo "[DryRun] openclaw doctor --repair --generate-gateway-token --yes --non-interactive"
        echo "[DryRun] openclaw gateway install --force --token <generated-token>"
        echo "[DryRun] openclaw dashboard"
        return 0
    fi

    ensure_openclaw_bootstrap_config
    openclaw doctor --repair --generate-gateway-token --yes --non-interactive || true

    local gateway_token
    gateway_token="$(get_gateway_token_from_config)"
    if [[ -n "$gateway_token" ]]; then
        openclaw gateway install --force --token "$gateway_token" || true
    else
        echo "未能从本地配置读取 gateway token，将继续尝试默认 gateway 安装。"
        openclaw gateway install --force || true
    fi

    openclaw gateway status --json >/dev/null 2>&1 || true

    if [[ "$NO_DASHBOARD" -eq 1 ]]; then
        echo "已按要求跳过控制台自动打开，稍后可手动执行：openclaw dashboard"
    else
        echo "正在打开 OpenClaw 控制台..."
        openclaw dashboard || true
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
        --official-installer-url)
            OFFICIAL_INSTALL_URL="${2:-}"
            shift 2
            ;;
        --uninstall)
            UNINSTALL=1
            shift
            ;;
        --purge-data)
            PURGE_DATA=1
            shift
            ;;
        --no-onboard)
            NO_ONBOARD=1
            shift
            ;;
        --onboard)
            NO_ONBOARD=0
            shift
            ;;
        --no-dashboard)
            NO_DASHBOARD=1
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
            print_banner
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

print_banner

if [[ "$UNINSTALL" -eq 1 ]]; then
    uninstall_openclaw
    exit 0
fi

tmp_file="$(mktemp "${TMPDIR:-/tmp}/openclaw-official-install.XXXXXX.sh")"
cleanup() {
    rm -f "$tmp_file"
}
trap cleanup EXIT

ensure_macos_prereqs

echo "正在下载 OpenClaw 官方安装器..."
installer_candidates=()
while IFS= read -r candidate; do
    [[ -n "$candidate" ]] && installer_candidates+=("$candidate")
done < <(build_official_installer_candidates)
download_to "$tmp_file" "${installer_candidates[@]}"

official_args=()
if [[ -n "$INSTALL_METHOD" ]]; then
    official_args+=(--install-method "$INSTALL_METHOD")
fi
if [[ "$USE_BETA" -eq 1 ]]; then
    official_args+=(--beta)
fi
if [[ -n "$VERSION" && "$VERSION" != "$DEFAULT_OPENCLAW_VERSION" ]]; then
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

echo "已切换到安装器路径：${DOWNLOADED_FROM_URL:-$OFFICIAL_INSTALL_URL}"
echo "即将执行：bash <official-installer> ${official_args[*]:-}"
echo

if [[ ${#official_args[@]} -gt 0 ]]; then
    invoke_official_installer "$tmp_file" "${official_args[@]}"
else
    invoke_official_installer "$tmp_file"
fi

bootstrap_first_launch
