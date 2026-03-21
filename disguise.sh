#!/usr/bin/env bash
# =============================================================================
#  3x-ui 登录页伪装工具 │ 3x-ui Login Page Disguise Tool
# =============================================================================
#  版本  / Version    : 1.1.0
#  用途  / Purpose    : 将 3x-ui 面板登录页替换为普通 PHP 网站管理页外观
#                       Disguise the 3x-ui login page as a generic PHP console
#  适用  / Applies to : 任何已安装 3x-ui (mhsanaei/3x-ui v2.x) 的 Linux 服务器
#  依赖  / Requires   : root 权限, python3
#  用法  / Usage      :
#    bash disguise.sh             # 交互式菜单 / interactive menu
#    bash disguise.sh install     # 安装伪装 / install disguise
#    bash disguise.sh remove      # 卸载伪装 / remove disguise
#    bash disguise.sh status      # 查看状态 / show status
#    bash disguise.sh restore     # 强制恢复原始二进制 / force-restore backup
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[0;34m'; P='\033[0m'

# ── Configuration ─────────────────────────────────────────────────────────────
XUI_FOLDER="${XUI_MAIN_FOLDER:-/usr/local/x-ui}"
XUI_BIN="$XUI_FOLDER/x-ui"
BACKUP_DIR="/etc/x-ui-disguise"
BACKUP_BIN="$BACKUP_DIR/x-ui.bak"
FLAG_FILE="$BACKUP_DIR/.disguise_active"
LOG_FILE="$BACKUP_DIR/disguise.log"
TOOL_VER="1.1.0"

# ── Logging & output helpers ──────────────────────────────────────────────────
_log() { mkdir -p "$BACKUP_DIR" 2>/dev/null; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE" 2>/dev/null || true; }
ok()   { echo -e "${G}[✓]${P} $*";  _log "OK: $*"; }
warn() { echo -e "${Y}[!]${P} $*";  _log "WARN: $*"; }
fail() { echo -e "${R}[✗]${P} $*" >&2; _log "ERR: $*"; }
info() { echo -e "${C}[i]${P} $*"; }
sep()  { echo -e "${B}────────────────────────────────────────────────${P}"; }

# ── Prerequisite checks ───────────────────────────────────────────────────────
check_root() {
    [[ $EUID -eq 0 ]] || { fail "请以 root 身份运行 / Please run as root"; exit 1; }
}

check_deps() {
    command -v python3 &>/dev/null || {
        fail "需要 python3 / python3 is required"
        fail "安装命令: apt install python3  或  yum install python3"
        exit 1
    }
}

check_xui() {
    [[ -f "$XUI_BIN" ]] || {
        fail "未找到 3x-ui 程序: $XUI_BIN"
        fail "如果安装在非默认路径，请设置环境变量: export XUI_MAIN_FOLDER=/your/path"
        exit 1
    }
}

is_installed() { [[ -f "$FLAG_FILE" ]] && [[ -f "$BACKUP_BIN" ]]; }

# ── Service management ────────────────────────────────────────────────────────
restart_xui() {
    info "重启 x-ui 服务..."
    if command -v systemctl &>/dev/null && systemctl list-units --type=service 2>/dev/null | grep -q x-ui; then
        systemctl restart x-ui && ok "x-ui 重启成功" || { warn "systemctl 重启失败，尝试 service 命令..."; service x-ui restart && ok "x-ui 重启成功"; }
    elif command -v service &>/dev/null; then
        service x-ui restart && ok "x-ui 重启成功" || warn "重启失败，请手动重启: systemctl restart x-ui"
    else
        warn "无法自动重启，请手动执行: $XUI_FOLDER/x-ui run  或  systemctl restart x-ui"
    fi
}

# ── Compact fake PHP-style login page HTML ────────────────────────────────────
# 注意: window.location.pathname 在运行时自动检测 base_path, 无需硬编码
# Note: base_path is auto-detected at runtime via window.location.pathname
FAKE_HTML='<!DOCTYPE html><html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="generator" content="PHP/8.1.2">
<meta name="robots" content="noindex,nofollow">
<title>Web Management Console</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font:13px Arial,sans-serif;background:#d0d0d0;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:20px;color:#333}
#box{background:#fff;border:1px solid #aaa;border-radius:3px;width:100%;max-width:380px;box-shadow:2px 2px 5px rgba(0,0,0,.2)}
.hd{background:#f0f0f0;border-bottom:1px solid #ccc;padding:10px 16px;display:flex;align-items:center;gap:8px}
.hd svg{flex-shrink:0}.hd h1{font-size:14px;font-weight:bold;color:#444;margin:0}
.bd{padding:20px}.dc{margin-bottom:14px;color:#666;font-size:11px;line-height:1.5}
#msg{margin-bottom:10px;padding:7px 10px;border-radius:2px;font-size:12px;display:none}
#msg.e{background:#fde;border:1px solid #f5c;color:#a00}
.rw{margin-bottom:12px}
.rw label{display:block;font-size:11px;color:#555;margin-bottom:3px;font-weight:bold}
.rw input{width:100%;padding:6px 8px;border:1px solid #bbb;border-radius:2px;font-size:13px;outline:none}
.rw input:focus{border-color:#6a9;box-shadow:0 0 3px rgba(80,160,80,.25)}
.ac{display:flex;align-items:center;justify-content:flex-end;gap:10px;margin-top:16px}
.btn{padding:6px 18px;background:#5a8;border:1px solid #4a7;color:#fff;font-size:13px;border-radius:2px;cursor:pointer}
.btn:hover{background:#4a7}.btn:disabled{background:#9ab;border-color:#8aa;cursor:not-allowed}
#sp{display:none;font-size:11px;color:#888}
footer{margin-top:10px;font-size:10px;color:#888;text-align:center}
</style>
</head>
<body>
<div id="box">
<div class="hd">
<svg width="22" height="22" viewBox="0 0 24 24" fill="none"><rect width="24" height="24" rx="3" fill="#5a8"/><path d="M6 8h12M6 12h12M6 16h8" stroke="#fff" stroke-width="2" stroke-linecap="round"/></svg>
<h1>Web Management Console</h1>
</div>
<div class="bd">
<p class="dc">Enter your administrator credentials to access the management console.</p>
<div id="msg"></div>
<form id="f" onsubmit="go(event)">
<div class="rw"><label>Username</label><input type="text" id="u" autocomplete="username" autofocus required placeholder="admin"></div>
<div class="rw"><label>Password</label><input type="password" id="pw" autocomplete="current-password" required placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;"></div>
<div class="rw" id="tfa" style="display:none"><label>Verification Code</label><input type="text" id="vc" autocomplete="one-time-code" placeholder="6-digit code" maxlength="8" inputmode="numeric"></div>
<div class="ac"><span id="sp">Authenticating&hellip;</span><button type="submit" class="btn" id="sb">Log In</button></div>
</form>
</div>
</div>
<footer>Powered by PHP/8.1.2 &bull; Web Management System</footer>
<script>
var B=(function(){var p=window.location.pathname;return p.endsWith("/")?p:p.substring(0,p.lastIndexOf("/")+1);}());
(function(){var x=new XMLHttpRequest();x.open("POST",B+"getTwoFactorEnable",true);x.setRequestHeader("Content-Type","application/json");x.setRequestHeader("X-Requested-With","XMLHttpRequest");x.onload=function(){try{var r=JSON.parse(x.responseText);if(r.success&&r.obj===true)document.getElementById("tfa").style.display="";}catch(e){}};x.send("{}");}());
function go(e){e.preventDefault();
var u=document.getElementById("u").value.trim(),pw=document.getElementById("pw").value.trim(),vc=(document.getElementById("vc")||{value:""}).value.trim(),m=document.getElementById("msg");
m.style.display="none";
if(!u||!pw){m.className="e";m.textContent="Username and password are required.";m.style.display="block";return;}
document.getElementById("sb").disabled=true;document.getElementById("sp").style.display="inline";
var x=new XMLHttpRequest();x.open("POST",B+"login",true);x.setRequestHeader("Content-Type","application/json");x.setRequestHeader("X-Requested-With","XMLHttpRequest");
x.onload=function(){document.getElementById("sb").disabled=false;document.getElementById("sp").style.display="none";
try{var r=JSON.parse(x.responseText);if(r.success){window.location.href=B+"panel/";}else{m.className="e";m.textContent=r.msg||"Invalid credentials.";m.style.display="block";}}
catch(ex){m.className="e";m.textContent="An error occurred. Please try again.";m.style.display="block";}};
x.onerror=function(){document.getElementById("sb").disabled=false;document.getElementById("sp").style.display="none";m.className="e";m.textContent="Network error. Please check your connection.";m.style.display="block";};
x.send(JSON.stringify({username:u,password:pw,twoFactorCode:vc}));}
</script>
</body></html>'

# ── Python binary patcher (run inline) ───────────────────────────────────────
# Strategy: search for unique Go template anchors that exist in login.html,
#           locate the surrounding template region, replace in-place (same size,
#           padded with spaces – harmless trailing whitespace after </html>).
#
# This modifies the 3x-ui binary on disk; no source code compilation required.
# Backup is kept; 'restore' reverses the patch byte-for-byte.
_run_patcher() {
    local action="$1"   # "patch" | "verify"
    local bin_path="$2"
    local fake_html="$3"

    # Write fake HTML to a temp file so we avoid heredoc interpolation issues
    # (the HTML contains single/double quotes that could confuse shell substitution).
    local tmp_html
    tmp_html=$(mktemp /tmp/xui_disguise_fake.XXXXXX.html)
    printf '%s' "$fake_html" > "$tmp_html"
    trap 'rm -f "$tmp_html"' RETURN

    python3 - "$action" "$bin_path" "$tmp_html" << 'PYEOF'
import sys, os

action       = sys.argv[1]
bin_path     = sys.argv[2]
fake_html_fp = sys.argv[3]

with open(fake_html_fp, "rb") as fh:
    fake_html = fh.read()

try:
    with open(bin_path, "rb") as fh:
        data = bytearray(fh.read())
except OSError as exc:
    print(f"ERROR: Cannot read binary: {exc}", file=sys.stderr)
    sys.exit(1)

# ---- Locate login.html inside the embed.FS data ----------------------------
# Go's embed.FS stores file content verbatim (uncompressed) in the binary.
# We search for strings that are unique to login.html.
ANCHORS = [
    b"async getTwoFactorEnable()",   # Vue method in login.html
    b"initHeadline()",               # Animation helper, login.html only
    b"pages.login.hello",            # i18n key unique to login page
    b'class="login-app"',            # Root element class
]
TSTART = b'{{ template "page/head_start" .}}'
TEND   = b'{{ template "page/body_end" .}}'

# Search window: login.html is typically ~10 KB, so 48 KB gives ample room
SEARCH_WINDOW = 49152  # 48 KB

anchor_pos = -1
for anchor in ANCHORS:
    anchor_pos = data.find(anchor)
    if anchor_pos != -1:
        break

if anchor_pos == -1:
    print("ERROR: Cannot locate login page in binary.", file=sys.stderr)
    print("  This binary may already be patched, compressed (UPX), or an", file=sys.stderr)
    print("  unsupported version. Aborting.", file=sys.stderr)
    sys.exit(2)

# Search backward within SEARCH_WINDOW bytes for the template-start marker
start = data.rfind(TSTART, max(0, anchor_pos - SEARCH_WINDOW), anchor_pos)
if start == -1:
    print("ERROR: Could not find template start marker.", file=sys.stderr)
    sys.exit(1)

# Search forward for template-end marker
end = data.find(TEND, anchor_pos)
if end == -1:
    print("ERROR: Could not find template end marker.", file=sys.stderr)
    sys.exit(1)
end += len(TEND)
# consume the trailing newline if present
if end < len(data) and data[end] in (10, 13):
    end += 1

region_len = end - start

if action == "verify":
    print(f"OK: login template found at offset {start}, size {region_len} bytes")
    sys.exit(0)

# ---- Patch ------------------------------------------------------------------
if len(fake_html) > region_len:
    print(f"ERROR: Replacement ({len(fake_html)} B) exceeds original ({region_len} B).", file=sys.stderr)
    sys.exit(1)

# Pad to exactly the original size with spaces (valid trailing HTML whitespace)
padded = fake_html + b" " * (region_len - len(fake_html))
if len(padded) != region_len:
    print("ERROR: Padding size mismatch — aborting without writing.", file=sys.stderr)
    sys.exit(1)

data[start:end] = padded

try:
    with open(bin_path, "wb") as fh:
        fh.write(bytes(data))
except OSError as exc:
    print(f"ERROR: Cannot write binary: {exc}", file=sys.stderr)
    sys.exit(1)

print(f"OK: Patched {region_len} bytes at offset {start}")
PYEOF
}

# ── Core actions ──────────────────────────────────────────────────────────────

do_install() {
    check_root
    check_deps
    check_xui
    sep
    echo -e "${C} 3x-ui 登录页伪装工具 v${TOOL_VER}${P}"
    sep

    if is_installed; then
        warn "伪装已安装。如需重新安装，请先运行 'bash disguise.sh remove'。"
        exit 0
    fi

    # 1. Verify the patcher can locate the login template before touching anything
    info "检测 3x-ui 二进制文件中的登录页模板..."
    if ! _run_patcher verify "$XUI_BIN" "$FAKE_HTML" 2>&1; then
        fail "模板定位失败，无法继续。"
        fail "请确认 3x-ui 版本为 mhsanaei/3x-ui v2.x，且未使用 UPX 压缩。"
        exit 1
    fi
    ok "登录页模板定位成功"

    # 2. Backup the original binary
    mkdir -p "$BACKUP_DIR"
    info "备份原始二进制文件 → $BACKUP_BIN"
    cp -f "$XUI_BIN" "$BACKUP_BIN"
    ok "备份完成 ($(du -sh "$BACKUP_BIN" | cut -f1))"

    # 3. Patch the binary
    info "正在修改登录页..."
    if ! _run_patcher patch "$XUI_BIN" "$FAKE_HTML"; then
        fail "补丁应用失败，正在还原..."
        cp -f "$BACKUP_BIN" "$XUI_BIN"
        fail "已还原原始文件。"
        exit 1
    fi
    ok "登录页已替换为 PHP 风格伪装页面"

    # 4. Mark as installed
    echo "$TOOL_VER $(date '+%Y-%m-%d %H:%M:%S')" > "$FLAG_FILE"

    # 5. Restart service
    restart_xui

    sep
    ok "安装完成！"
    info "现在访问面板登录地址，将看到 PHP 风格的网页管理控制台。"
    info "如果界面显示错误，请立即运行: bash disguise.sh restore"
    sep
}

do_remove() {
    check_root
    sep
    echo -e "${C} 3x-ui 登录页伪装工具 v${TOOL_VER} — 卸载${P}"
    sep

    if ! is_installed; then
        warn "伪装未安装或备份文件不存在。"
        info "如果需要强制恢复，请运行: bash disguise.sh restore"
        exit 0
    fi

    info "从备份还原原始二进制文件..."
    cp -f "$BACKUP_BIN" "$XUI_BIN"
    ok "原始文件已还原"

    rm -f "$FLAG_FILE" "$BACKUP_BIN"
    ok "备份和状态文件已清理"

    restart_xui

    sep
    ok "伪装已卸载，登录页已恢复原始样式。"
    sep
}

do_restore() {
    check_root
    sep
    echo -e "${C} 3x-ui 登录页伪装工具 v${TOOL_VER} — 强制恢复${P}"
    sep

    if [[ ! -f "$BACKUP_BIN" ]]; then
        fail "备份文件不存在: $BACKUP_BIN"
        fail "无法还原。请重新安装 3x-ui。"
        exit 1
    fi

    warn "此操作将强制还原 3x-ui 二进制文件到备份版本。"
    echo -ne "${Y}确认继续? [y/N]: ${P}"
    read -r confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "已取消。"; exit 0; }

    cp -f "$BACKUP_BIN" "$XUI_BIN"
    ok "原始文件已强制还原"

    # Keep backup in case user needs it again, just clear the active flag
    rm -f "$FLAG_FILE"

    restart_xui

    sep
    ok "强制恢复完成！3x-ui 登录页已恢复为原始样式。"
    sep
}

do_status() {
    sep
    echo -e "${C} 3x-ui 登录页伪装工具 v${TOOL_VER} — 状态${P}"
    sep

    # Binary
    if [[ -f "$XUI_BIN" ]]; then
        ok "3x-ui 程序存在: $XUI_BIN ($(du -sh "$XUI_BIN" | cut -f1))"
    else
        fail "3x-ui 程序不存在: $XUI_BIN"
    fi

    # Disguise flag
    if is_installed; then
        local install_info
        install_info=$(cat "$FLAG_FILE" 2>/dev/null || echo "unknown")
        ok "伪装状态: 已安装 (v${install_info%% *}, $(echo "$install_info" | cut -d' ' -f2-))"
    else
        warn "伪装状态: 未安装"
    fi

    # Backup
    if [[ -f "$BACKUP_BIN" ]]; then
        ok "备份文件: $BACKUP_BIN ($(du -sh "$BACKUP_BIN" | cut -f1))"
    else
        warn "备份文件: 不存在"
    fi

    # Service
    if command -v systemctl &>/dev/null; then
        if systemctl is-active --quiet x-ui 2>/dev/null; then
            ok "x-ui 服务: 运行中"
        else
            warn "x-ui 服务: 未运行"
        fi
    fi

    # Verify binary has fake page (if installed)
    if is_installed; then
        if python3 -c "import sys; d=open('$XUI_BIN','rb').read(); sys.exit(0 if b'Web Management Console' in d else 1)" 2>/dev/null; then
            ok "二进制文件: 包含伪装页面 ✓"
        else
            warn "二进制文件: 未检测到伪装页面内容（可能已被覆盖）"
        fi
    fi

    # Log
    if [[ -f "$LOG_FILE" ]]; then
        info "日志文件: $LOG_FILE (最近5条)"
        tail -5 "$LOG_FILE" 2>/dev/null | sed 's/^/  /'
    fi
    sep
}

# ── Interactive menu ──────────────────────────────────────────────────────────
show_menu() {
    clear 2>/dev/null || true
    sep
    echo -e "${C}  3x-ui 登录页伪装工具  v${TOOL_VER}${P}"
    sep
    if is_installed; then
        echo -e "  伪装状态: ${G}已安装${P}"
    else
        echo -e "  伪装状态: ${Y}未安装${P}"
    fi
    sep
    echo -e "  ${G}1.${P} 安装伪装（替换登录页为 PHP 风格）"
    echo -e "  ${G}2.${P} 卸载伪装（恢复原始登录页）"
    echo -e "  ${G}3.${P} 强制恢复（紧急修复 / 回退）"
    echo -e "  ${G}4.${P} 查看状态"
    echo -e "  ${G}0.${P} 退出"
    sep
    echo -ne "${Y}请选择 [0-4]: ${P}"
    read -r choice
    case "$choice" in
        1) do_install ;;
        2) do_remove ;;
        3) do_restore ;;
        4) do_status ;;
        0) echo -e "${G}再见！${P}"; exit 0 ;;
        *) warn "无效选项，请输入 0-4"; sleep 1; show_menu ;;
    esac
    echo
    echo -ne "${Y}按 Enter 返回菜单...${P}"; read -r
    show_menu
}

# ── Entry point ───────────────────────────────────────────────────────────────
main() {
    case "${1:-menu}" in
        install)  do_install  ;;
        remove)   do_remove   ;;
        restore)  do_restore  ;;
        status)   do_status   ;;
        menu|"")  show_menu   ;;
        -v|--version) echo "disguise.sh v$TOOL_VER"; exit 0 ;;
        *)
            echo -e "用法 / Usage: bash disguise.sh [install|remove|restore|status]"
            echo -e "  install  安装伪装"
            echo -e "  remove   卸载伪装"
            echo -e "  restore  强制恢复（紧急）"
            echo -e "  status   查看状态"
            exit 1
            ;;
    esac
}

main "$@"
