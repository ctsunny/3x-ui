#!/usr/bin/env bash
# =============================================================================
#  3x-ui 登录页伪装工具 │ 3x-ui Login Page Disguise Tool
# =============================================================================
#  版本  / Version    : 2.0.0
#  用途  / Purpose    : 启用/禁用 3x-ui 面板登录页 PHP 风格伪装
#                       Enable/disable the PHP-style login page disguise
#  适用  / Applies to : ctsunny/3x-ui v0.1.4+ (内置伪装功能 / built-in disguise)
#  依赖  / Requires   : root 权限, sqlite3
#  用法  / Usage      :
#    bash disguise.sh             # 交互式菜单 / interactive menu
#    bash disguise.sh install     # 启用伪装 / enable disguise
#    bash disguise.sh remove      # 禁用伪装 / disable disguise
#    bash disguise.sh status      # 查看状态 / show status
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[0;34m'; P='\033[0m'

# ── Configuration ─────────────────────────────────────────────────────────────
DB_PATH="${XUI_DB_PATH:-/etc/x-ui/x-ui.db}"
TOOL_VER="2.0.0"
VERBOSE=0

# ── Output helpers ────────────────────────────────────────────────────────────
ok()   { echo -e "${G}[✓]${P} $*"; }
warn() { echo -e "${Y}[!]${P} $*"; }
fail() { echo -e "${R}[✗]${P} $*" >&2; }
info() { [[ $VERBOSE -eq 1 ]] && echo -e "${C}[i]${P} $*"; return 0; }
sep()  { [[ $VERBOSE -eq 1 ]] && echo -e "${B}────────────────────────────────────────────────${P}"; return 0; }

# ── Prerequisite checks ───────────────────────────────────────────────────────
check_root() {
    [[ $EUID -eq 0 ]] || { fail "请以 root 身份运行 / Please run as root"; exit 1; }
}

check_deps() {
    command -v sqlite3 &>/dev/null || {
        fail "需要 sqlite3 / sqlite3 is required"
        fail "安装命令: apt install sqlite3  或  yum install sqlite3"
        exit 1
    }
}

check_db() {
    [[ -f "$DB_PATH" ]] || {
        fail "未找到数据库: $DB_PATH"
        fail "Database not found: $DB_PATH"
        fail "如果数据库在非默认路径，请设置: export XUI_DB_PATH=/your/path/x-ui.db"
        exit 1
    }
}

# ── Database helpers ──────────────────────────────────────────────────────────
get_disguise_status() {
    local val
    val=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='disguiseLoginPage' LIMIT 1;" 2>/dev/null || echo "")
    [[ "$val" == "true" ]]
}

set_disguise_setting() {
    local value="$1"
    local exists
    exists=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM settings WHERE key='disguiseLoginPage';" 2>/dev/null || echo "0")
    if [[ "$exists" -gt 0 ]]; then
        sqlite3 "$DB_PATH" "UPDATE settings SET value='$value' WHERE key='disguiseLoginPage';"
    else
        sqlite3 "$DB_PATH" "INSERT INTO settings (key, value) VALUES ('disguiseLoginPage', '$value');"
    fi
}

# ── Service management ────────────────────────────────────────────────────────
restart_xui() {
    info "重启 x-ui 服务..."
    if command -v systemctl &>/dev/null && systemctl list-units --type=service 2>/dev/null | grep -q x-ui; then
        systemctl restart x-ui && ok "x-ui 重启成功 / x-ui restarted" || warn "重启失败 / restart failed"
    elif command -v service &>/dev/null; then
        service x-ui restart && ok "x-ui 重启成功 / x-ui restarted" || warn "重启失败 / restart failed"
    else
        warn "无法自动重启，请手动执行: systemctl restart x-ui"
        warn "Cannot auto-restart. Run manually: systemctl restart x-ui"
    fi
}

# ── Core actions ──────────────────────────────────────────────────────────────

do_install() {
    check_root
    check_deps
    check_db
    sep

    if get_disguise_status; then
        warn "伪装已启用 / Disguise is already enabled"
        info "如需禁用，请运行: bash disguise.sh remove"
        exit 0
    fi

    set_disguise_setting "true"
    ok "伪装已启用 / Disguise enabled in database"

    echo -ne "${Y}是否立即重启 x-ui 使设置生效? Restart x-ui now? [Y/n]: ${P}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
        restart_xui
    else
        warn "请手动重启 x-ui 使设置生效: systemctl restart x-ui"
        warn "Please restart x-ui manually: systemctl restart x-ui"
    fi

    sep
    ok "安装完成！登录页将显示为 PHP 风格管理控制台。"
    ok "Done! Login page will appear as a PHP-style management console."
    sep
}

do_remove() {
    check_root
    check_deps
    check_db
    sep

    if ! get_disguise_status; then
        warn "伪装未启用 / Disguise is not enabled"
        exit 0
    fi

    set_disguise_setting "false"
    ok "伪装已禁用 / Disguise disabled in database"

    echo -ne "${Y}是否立即重启 x-ui 使设置生效? Restart x-ui now? [Y/n]: ${P}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
        restart_xui
    else
        warn "请手动重启 x-ui 使设置生效: systemctl restart x-ui"
        warn "Please restart x-ui manually: systemctl restart x-ui"
    fi

    sep
    ok "伪装已卸载，登录页已恢复原始样式。"
    ok "Disguise removed, login page restored to original."
    sep
}

do_status() {
    VERBOSE=1
    check_deps
    check_db
    sep
    echo -e "${C}  3x-ui 登录页伪装工具  v${TOOL_VER}${P}"
    sep

    if get_disguise_status; then
        ok "伪装状态: 已启用 / Disguise: Enabled"
    else
        warn "伪装状态: 未启用 / Disguise: Disabled"
    fi

    # Service
    if command -v systemctl &>/dev/null; then
        if systemctl is-active --quiet x-ui 2>/dev/null; then
            ok "x-ui 服务: 运行中 / Service: Running"
        else
            warn "x-ui 服务: 未运行 / Service: Not running"
        fi
    fi

    info "数据库路径 / DB path: $DB_PATH"
    sep
}

# ── Interactive menu ──────────────────────────────────────────────────────────
show_menu() {
    VERBOSE=1
    clear 2>/dev/null || true
    sep
    echo -e "${C}  3x-ui 登录页伪装工具  v${TOOL_VER}${P}"
    sep
    if check_deps 2>/dev/null && check_db 2>/dev/null && get_disguise_status 2>/dev/null; then
        echo -e "  伪装状态: ${G}已启用 / Enabled${P}"
    else
        echo -e "  伪装状态: ${Y}未启用 / Disabled${P}"
    fi
    sep
    echo -e "  ${G}1.${P} 启用伪装 / Enable disguise"
    echo -e "  ${G}2.${P} 禁用伪装 / Disable disguise"
    echo -e "  ${G}3.${P} 查看状态 / Show status"
    echo -e "  ${G}0.${P} 退出 / Exit"
    sep
    echo -ne "${Y}请选择 / Choose [0-3]: ${P}"
    read -r choice
    case "$choice" in
        1) do_install ;;
        2) do_remove ;;
        3) do_status ;;
        0) echo -e "${G}再见！/ Bye!${P}"; exit 0 ;;
        *) warn "无效选项 / Invalid option"; sleep 1; show_menu ;;
    esac
    echo
    echo -ne "${Y}按 Enter 返回菜单... / Press Enter for menu...${P}"; read -r
    show_menu
}

# ── Entry point ───────────────────────────────────────────────────────────────
main() {
    local args=()
    for arg in "$@"; do
        case "$arg" in
            --verbose) VERBOSE=1 ;;
            *) args+=("$arg") ;;
        esac
    done

    case "${args[0]:-menu}" in
        install|enable)   do_install ;;
        remove|disable)   do_remove  ;;
        status)           do_status  ;;
        menu|"")          show_menu  ;;
        -v|--version)     echo "disguise.sh v$TOOL_VER"; exit 0 ;;
        *)
            echo -e "用法 / Usage: bash disguise.sh [install|remove|status] [--verbose]"
            echo -e "  install    启用伪装 / Enable disguise"
            echo -e "  remove     禁用伪装 / Disable disguise"
            echo -e "  status     查看状态 / Show status"
            echo -e "  --verbose  详细信息 / Verbose output"
            exit 1
            ;;
    esac
}

main "$@"
