# 3x-ui 登录页伪装工具

> 将 3x-ui 面板登录页一键替换为普通 **PHP 网站管理控制台** 外观，隐藏真实面板身份。
> 适用于**任何**已安装 mhsanaei/3x-ui v2.x 的 Linux 服务器，无需重新编译，支持一键回退。

![伪装效果预览](https://github.com/user-attachments/assets/3103945f-c995-4ec8-a89e-4d68249ef6c4)

---

## 目录

- [原理说明](#原理说明)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [详细用法](#详细用法)
  - [安装伪装](#安装伪装)
  - [查看状态](#查看状态)
  - [卸载伪装](#卸载伪装)
  - [紧急恢复（回退）](#紧急恢复回退)
  - [交互式菜单](#交互式菜单)
- [常见问题](#常见问题)
- [安全建议](#安全建议)

---

## 原理说明

3x-ui 的面板页面（包括登录页）以 **Go embed.FS** 方式直接编译嵌入到二进制文件中，存储为**明文字节**，无需解压。  
本工具通过 Python3 在已安装的 `x-ui` 二进制文件中定位 `login.html` 模板区域，将其**原地替换**为紧凑的 PHP 风格假页面（等长填充，保持二进制完整性），再重启服务即可生效。

- **不需要** nginx / Caddy 等反代  
- **不修改** 3x-ui 源码或任何配置文件  
- **登录接口**（`POST /login`）仍由 3x-ui 处理，功能完全正常  
- 安装前自动备份原始二进制，一键可还原

---

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Linux（Debian / Ubuntu / CentOS / Alpine 均可） |
| 3x-ui 版本 | mhsanaei/3x-ui v2.x（二进制默认安装在 `/usr/local/x-ui/`） |
| 运行权限 | **root** |
| Python 版本 | python3（绝大多数发行版已预装） |

---

## 快速开始

> **安全提示**：建议先下载脚本查看内容，确认无误后再执行。

```bash
# 方式一：查看后执行（推荐）
curl -Lo disguise.sh https://raw.githubusercontent.com/ctsunny/3x-ui/main/disguise.sh
cat disguise.sh   # 先查看内容
bash disguise.sh install

# 方式二：一键安装（信任来源时使用）
bash <(curl -Ls https://raw.githubusercontent.com/ctsunny/3x-ui/main/disguise.sh) install
```

---

## 详细用法

### 安装伪装

```bash
bash disguise.sh install
```

执行流程：

1. 检测 3x-ui 二进制是否存在，定位登录页模板
2. 自动备份原始二进制 → `/etc/x-ui-disguise/x-ui.bak`
3. 将伪装页面（PHP 风格 HTML）写入二进制，等长填充
4. 重启 x-ui 服务使改动生效

安装完成后，访问 3x-ui 面板地址，登录页将显示为：

```
Web Management Console
Enter your administrator credentials to access the console.
[Username]  [Password]  [Log In]
Powered by PHP/8.1.2 • Web Management System
```

> **如果页面显示异常，请立即运行** `bash disguise.sh restore` **恢复。**

---

### 查看状态

```bash
bash disguise.sh status
```

输出示例：

```
────────────────────────────────────────────────
  3x-ui 登录页伪装工具 v1.1.0 — 状态
────────────────────────────────────────────────
[✓] 3x-ui 程序存在: /usr/local/x-ui/x-ui (82M)
[✓] 伪装状态: 已安装 (v1.1.0, 2024-01-01 12:00:00)
[✓] 备份文件: /etc/x-ui-disguise/x-ui.bak (82M)
[✓] x-ui 服务: 运行中
[✓] 二进制文件: 包含伪装页面 ✓
```

---

### 卸载伪装

```bash
bash disguise.sh remove
```

执行流程：

1. 从备份 `/etc/x-ui-disguise/x-ui.bak` 还原原始二进制
2. 删除状态文件和备份
3. 重启 x-ui 服务

卸载后，3x-ui 登录页恢复为原始的 Ant Design / Vue.js 风格界面。

---

### 紧急恢复（回退）

**如果安装后 Web 界面报错、无法登录或出现其他异常**，请立即执行：

```bash
bash disguise.sh restore
```

此命令会：
- 直接将备份二进制覆盖到 `/usr/local/x-ui/x-ui`
- 重启 x-ui 服务
- 清除安装标志

操作完成后登录页将立即恢复为原始样式。

> ⚠️ 如果连 SSH 都进不去，可通过 VNC/面板控制台登录后执行此命令。

---

### 交互式菜单

直接运行脚本（无参数）即可进入中文交互菜单：

```bash
bash disguise.sh
```

菜单界面：

```
────────────────────────────────────────────────
  3x-ui 登录页伪装工具  v1.1.0
────────────────────────────────────────────────
  伪装状态: 未安装
────────────────────────────────────────────────
  1. 安装伪装（替换登录页为 PHP 风格）
  2. 卸载伪装（恢复原始登录页）
  3. 强制恢复（紧急修复 / 回退）
  4. 查看状态
  0. 退出
────────────────────────────────────────────────
请选择 [0-4]:
```

---

## 常见问题

**Q: 安装后面板完全无法打开怎么办？**  
A: SSH 登录服务器，运行 `bash disguise.sh restore`，30 秒内即可恢复。

**Q: 适用于哪些 3x-ui 版本？**  
A: 适用于 mhsanaei/3x-ui v2.x 系列（使用 Go embed.FS 的版本）。  
如果报 "Cannot locate login page" 错误，说明此版本可能不兼容（例如使用了 UPX 压缩的构建版本）。

**Q: 3x-ui 更新后伪装还在吗？**  
A: **不在**。更新 3x-ui 会替换 `x-ui` 二进制，伪装会失效。  
更新完成后重新运行 `bash disguise.sh install` 即可。

**Q: 伪装页面能自定义吗？**  
A: 可以。编辑 `disguise.sh` 文件中的 `FAKE_HTML` 变量（脚本约第 60 行），替换为你自己的 HTML 即可（需保证小于 9.7 KB）。

**Q: 3x-ui 安装路径不在 `/usr/local/x-ui/`？**  
A: 通过环境变量指定：
```bash
XUI_MAIN_FOLDER=/your/custom/path bash disguise.sh install
```

**Q: 备份文件在哪里，占多大空间？**  
A: 备份保存在 `/etc/x-ui-disguise/x-ui.bak`，大小与 x-ui 二进制相同（约 80-90 MB）。

---

## 安全建议

- 伪装登录页能有效规避大多数自动化扫描器识别 3x-ui 指纹
- 建议同时：
  - 修改面板默认端口（非 2053）
  - 设置随机 URL 路径（webBasePath，如 `/abc123/`）
  - 启用 TLS 证书
  - 开启两步验证（2FA）
- 本工具不能阻止针对性的人工检测，仅用于降低被自动扫描识别的概率

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `disguise.sh` | 主脚本，包含所有功能 |
| `/etc/x-ui-disguise/x-ui.bak` | 原始二进制备份（安装后自动生成） |
| `/etc/x-ui-disguise/.disguise_active` | 安装状态标志文件 |
| `/etc/x-ui-disguise/disguise.log` | 操作日志 |
