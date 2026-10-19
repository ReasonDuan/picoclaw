# PicoClaw 飞牛 Native 应用打包指南

本方案不使用 Docker。构建阶段生成 Linux 二进制，打包阶段通过 `fnpack` 生成 `.fpk`。

## 1. 前置条件

开发机需要：

- Go 1.25+
- Node.js 22+
- pnpm
- 飞牛官方 `fnpack`
- 一台用于安装测试的 fnOS 设备

检查工具：

```bash
go version
node --version
pnpm --version
fnpack --help
```

## 2. 编译

```bash
./fnos/scripts/build-native.sh
```

默认生成：

```text
build/fnos/app/bin/picoclaw
build/fnos/app/bin/picoclaw-launcher
```

交叉编译示例：

```bash
GOARCH=arm64 ./fnos/scripts/build-native.sh
```

因为二进制包含架构信息，不能把同一个 Native 包声明为 `platform=all`。

## 3. 创建应用骨架

在仓库根目录执行：

```bash
fnpack create picoclaw
```

生成的 `picoclaw/` 应包含：

```text
picoclaw/
├── app/
│   └── ui/
│       ├── config
│       └── images/
├── cmd/
├── config/
│   ├── privilege
│   └── resource
├── wizard/
├── manifest
├── ICON.PNG
└── ICON_256.PNG
```

将编译产物放入：

```text
fnos/picoclaw/app/bin/picoclaw
fnos/picoclaw/app/bin/picoclaw-launcher
```

`build-native.sh` 会在包目录存在时自动复制这两个文件。

## 4. manifest 示例

x86_64 包：

```bash
appname=picoclaw
version=0.2.9
display_name=PicoClaw
desc=超轻量个人 AI 助手与 Web 控制台
source=thirdparty
platform=x86
maintainer=Your Name
maintainer_url=https://github.com/sipeed/picoclaw
distributor=Your Name
desktop_uidir=ui
desktop_applaunchname=picoclaw.main
service_port=18800
checkport=true
ctl_stop=true
```

ARM64 包改为：

```bash
platform=arm
```

## 5. 权限和资源

`config/privilege`：

```json
{
  "defaults": {
    "run-as": "package"
  },
  "username": "picoclaw",
  "groupname": "picoclaw"
}
```

默认 `config/resource`：

```json
{}
```

只有需要让用户从文件管理器访问工作区时，才声明 `data-share`。

## 6. 桌面入口

PicoClaw Web UI 使用 WebSocket，因此不要使用 CGI 入口。使用端口入口：

```json
{
  ".url": {
    "picoclaw.main": {
      "title": "PicoClaw",
      "icon": "images/icon_{0}.png",
      "type": "iframe",
      "protocol": "http",
      "port": "18800",
      "url": "/",
      "allUsers": false
    }
  }
}
```

## 7. 生命周期脚本

`cmd/main` 需要实现 `start`、`stop`、`status`：

- `start`：启动 `picoclaw-launcher`
- `stop`：向 Launcher 发送 `SIGTERM`
- `status`：运行返回 `0`，未运行返回 `3`

建议设置：

```bash
export PICOCLAW_HOME="${TRIM_PKGVAR}"
```

这样配置、工作区、日志和会话都保存在飞牛应用数据目录中。

Launcher 启动后会：

1. 在配置不存在时执行 onboard
2. 创建 `config.json`
3. 自动启动 Gateway
4. 在 `18800` 端口提供 Web UI

## 8. 构建 .fpk

```bash
FNPACK_BIN=/path/to/fnpack ./fnos/scripts/build-fpk.sh ./fnos/picoclaw
```

产物位置：

```text
dist/fnos/picoclaw.fpk
```

## 9. 安装测试

```bash
appcenter-cli install-fpk dist/fnos/picoclaw.fpk
```

重点验证：

- 桌面入口可以打开
- 首次初始化能创建配置
- Dashboard 密码可用
- Gateway 能启动和停止
- WebSocket 聊天可用
- 重启后数据仍然存在
- x86/ARM 目标架构与 `platform` 一致
- 未授权用户不能访问管理接口
