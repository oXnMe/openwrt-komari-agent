# openwrt-komari-agent

OpenWrt Komari Agent，可以选择 [komari-agent](https://github.com/komari-monitor/komari-agent)（官方原版）或 [komari-zig-agent](https://github.com/luodaoyi/komari-zig-agent)（Zig 版）。

## 快速开始

```bash
cd /path/to/openwrt

# 1. 添加到 OpenWrt 编译环境
echo "src-git komari-agent https://github.com/oXnMe/openwrt-komari-agent.git;main" >> feeds.conf
./scripts/feeds update komari-agent
./scripts/feeds install -a -p komari-agent

# 2. 选包（menuconfig 中选 Zig 或 Go 实现）
make menuconfig
# Network -> Monitoring -> komari-agent
# LuCI   -> Applications -> luci-app-komari-agent

# 3. 编译
make package/komari-agent/compile V=s
make package/luci-app-komari-agent/compile V=s
```

GitHub 代理（可选）：`make package/komari-agent/compile V=s GHPROXY=https://gh-proxy.org`

## 功能特性

- 编译期从 GitHub Releases 下载预编译二进制
- **双实现可选**：Zig（默认，轻量，支持 MIPS）或 Go（官方原版）
- 架构：x86 / ARM / MIPS / RISC-V / s390x / LoongArch（Zig 版）
- UCI 配置管理，LuCI 可视化界面
- 默认不启动，配置面板地址和 Token 后才运行
- 刷写固件保留配置时自动用旧配置启动

## 配置

LuCI 界面：`服务 → Komari Agent`

或 UCI 命令行：

```bash
uci set komari-agent.main.endpoint='https://panel.example.com'
uci set komari-agent.main.token='your-token'
uci set komari-agent.main.enabled='1'
uci commit komari-agent
/etc/init.d/komari-agent enable
/etc/init.d/komari-agent start
```

必填：`endpoint`、`token`。其余参数可选，留空使用 agent 内置默认值。
