#!/usr/bin/env bash
# =============================================================================
#  3x-ui 一键安装 + 登录页伪装  │  3x-ui Install + Login Page Disguise
# =============================================================================
#  用法 / Usage:
#    bash install_with_disguise.sh          # 安装最新版 / install latest
#    bash install_with_disguise.sh v2.x.x   # 安装指定版本 / install specific version
# =============================================================================

set -euo pipefail

REPO="https://raw.githubusercontent.com/ctsunny/3x-ui/main"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[0;34m'; P='\033[0m'

sep()  { echo -e "${B}────────────────────────────────────────────────${P}"; }
ok()   { echo -e "${G}[✓]${P} $*"; }
info() { echo -e "${C}[i]${P} $*"; }
fail() { echo -e "${R}[✗]${P} $*" >&2; }

[[ $EUID -eq 0 ]] || { fail "请以 root 身份运行 / Please run as root"; exit 1; }

command -v curl >/dev/null 2>&1 || { fail "需要 curl / curl is required"; exit 1; }

sep
echo -e "${C}  3x-ui 一键安装 + 登录页伪装${P}"
sep

# ── Step 1: Install 3x-ui ────────────────────────────────────────────────────
info "第一步：安装 3x-ui 面板..."
bash <(curl -Ls "$REPO/install.sh") "${1:-}"
ok "3x-ui 安装完成"

# ── Step 2: Apply login page disguise ────────────────────────────────────────
sep
info "第二步：应用登录页伪装..."
bash <(curl -Ls "$REPO/disguise.sh") install

sep
ok "全部完成！3x-ui 已安装并启用登录页伪装。"
info "如需卸载伪装，运行: bash <(curl -Ls $REPO/disguise.sh) remove"
sep
