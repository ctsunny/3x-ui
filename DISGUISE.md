# 3x-ui 登录页伪装工具

> 将 3x-ui 面板登录页替换为普通 **PHP 网站管理控制台** 外观，隐藏真实面板身份。
> 伪装功能已内置于程序中，通过面板设置或数据库开关即可启用/禁用，无需修改二进制文件。

![伪装效果预览](https://github.com/user-attachments/assets/3103945f-c995-4ec8-a89e-4d68249ef6c4)

---

## 目录

- [原理说明](#原理说明)
- [系统要求](#系统要求)
- [启用方式](#启用方式)
  - [方式一：面板设置（推荐）](#方式一面板设置推荐)
  - [方式二：命令行脚本](#方式二命令行脚本)
- [详细用法](#详细用法)
  - [启用伪装](#启用伪装)
  - [查看状态](#查看状态)
  - [禁用伪装](#禁用伪装)
- [从源码构建](#从源码构建)
- [常见问题](#常见问题)
- [安全建议](#安全建议)

---

## 原理说明

伪装功能已直接集成到 3x-ui 源码中。程序会根据数据库中的 `disguiseLoginPage` 设置项决定渲染哪个登录页模板：

- **关闭（默认）**：显示标准的 Vue.js / Ant Design 登录页
- **开启**：显示 PHP 风格的 Web Management Console 登录页

两种模式共享相同的后端登录接口（`POST /login`、`POST /getTwoFactorEnable`），功能完全一致，仅前端外观不同。

- **不需要** 修改二进制文件
- **不需要** nginx / Caddy 等反代
- 支持两步验证（2FA）
- 可随时在面板设置中开启/关闭

---

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Linux（Debian / Ubuntu / CentOS / Alpine 均可） |
| 3x-ui 版本 | ctsunny/3x-ui v0.1.4+（内置伪装功能） |
| 运行权限 | **root**（仅命令行脚本需要） |

---

## 启用方式

### 方式一：面板设置（推荐）

1. 登录 3x-ui 面板
2. 进入 **设置** → **安全** 选项卡
3. 找到 **登录页伪装** 部分
4. 开启 **启用登录页伪装** 开关
5. 点击 **保存并重启面板**

### 方式二：命令行脚本

```bash
# 下载并运行
curl -Lo disguise.sh https://raw.githubusercontent.com/ctsunny/3x-ui/main/disguise.sh
bash disguise.sh install

# 或一键执行
bash <(curl -Ls https://raw.githubusercontent.com/ctsunny/3x-ui/main/disguise.sh) install
```

> 命令行脚本通过 `sqlite3` 直接修改数据库设置，效果与面板操作相同。

---

## 详细用法

### 启用伪装

```bash
bash disguise.sh install
```

执行流程：
1. 检测数据库文件是否存在
2. 在数据库中设置 `disguiseLoginPage = true`
3. 重启 x-ui 服务使设置生效

启用后，访问面板登录页将显示为：

```
Web Management Console
Enter your administrator credentials to access the console.
[Username]  [Password]  [Log In]
Powered by PHP/8.1.2 • Web Management System
```

### 查看状态

```bash
bash disguise.sh status
```

### 禁用伪装

```bash
bash disguise.sh remove
```

禁用后，登录页恢复为标准的 Vue.js / Ant Design 风格界面。

---

## 从源码构建

如果你从源码构建 3x-ui，伪装功能已包含在代码中：

```bash
# 克隆仓库
git clone https://github.com/ctsunny/3x-ui.git
cd 3x-ui

# 构建（需要 Go 1.22+）
CGO_ENABLED=1 go build -o x-ui main.go

# 构建后的二进制已包含伪装功能
# 启用方式：面板设置 或 disguise.sh 脚本
```

### 交叉编译

```bash
# Linux amd64
CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o x-ui main.go

# Linux arm64
CGO_ENABLED=1 GOOS=linux GOARCH=arm64 go build -o x-ui main.go
```

> 注意：需要启用 CGO（`CGO_ENABLED=1`），因为 SQLite 驱动依赖 CGO。

---

## 常见问题

**Q: 3x-ui 更新后伪装还在吗？**
A: **在的**。伪装设置保存在数据库中，更新二进制不影响设置。只要新版本包含伪装功能，更新后自动生效。

**Q: 伪装页面能自定义吗？**
A: 可以。修改源码中的 `web/html/login/login_disguise.html` 模板文件，重新编译即可。

**Q: 数据库路径不在 `/etc/x-ui/x-ui.db`？**
A: 通过环境变量指定：
```bash
XUI_DB_PATH=/your/custom/path/x-ui.db bash disguise.sh install
```

**Q: 命令行脚本需要什么依赖？**
A: 只需要 `sqlite3`。安装方法：
```bash
apt install sqlite3    # Debian/Ubuntu
yum install sqlite     # CentOS/RHEL
```

---

## 安全建议

- 伪装登录页能有效规避大多数自动化扫描器识别 3x-ui 指纹
- 建议同时：
  - 修改面板默认端口（非 2053）
  - 设置随机 URL 路径（webBasePath，如 `/abc123/`）
  - 启用 TLS 证书
  - 开启两步验证（2FA）
- 本功能不能阻止针对性的人工检测，仅用于降低被自动扫描识别的概率
