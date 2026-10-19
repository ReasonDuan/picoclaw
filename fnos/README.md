# PicoClaw 飞牛应用打包

这个目录用于存放将 PicoClaw 制作成飞牛 fnOS 原生应用的脚本和文档。方案不依赖 Docker，直接编译并携带：

- `picoclaw`：PicoClaw 核心程序
- `picoclaw-launcher`：Web UI 与 Gateway 管理器

## 目录

```text
fnos/
├── README.md
├── scripts/
│   ├── build-native.sh    # 编译当前架构的两个 Linux 二进制
│   └── build-fpk.sh       # 调用 fnpack 构建 .fpk
└── docs/
    └── packaging-guide.md # 打包步骤、manifest 和生命周期脚本说明
```

## 快速开始

```bash
# 1. 编译（需要 Go 1.25+、Node.js 22+、pnpm）
./fnos/scripts/build-native.sh

# 2. 创建飞牛应用包骨架（只需执行一次）
cd fnos
fnpack create picoclaw
cd ..

# 3. 按 docs/packing-guide.md 填写 manifest、cmd、入口和图标

# 4. 构建 .fpk
FNPACK_BIN=/path/to/fnpack ./fnos/scripts/build-fpk.sh ./fnos/picoclaw
```

构建产物默认写入 `build/fnos/`，生成的 `.fpk` 默认写入 `dist/fnos/`。这些目录均不应提交到 Git。

## 当前方案

原生方案必须按目标 CPU 架构分别打包：

- x86_64：`GOARCH=amd64`
- ARM64：`GOARCH=arm64`

因此 `manifest` 中不能使用 `platform=all`，而应分别使用 `platform=x86` 或 `platform=arm`。
