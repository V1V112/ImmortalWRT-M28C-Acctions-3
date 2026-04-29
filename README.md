# ImmortalWrt M28C GitHub Actions Builder

这是给 Widora MangoPi M28C 准备的 ImmortalWrt 自动编译项目。默认编译 `openwrt-25.12`，目标为 `rockchip/armv8/widora_mangopi-m28c`，并预置 momo、SmartDNS、第三方 MosDNS、QModem Next、PWM 风扇控制和华为 5G 模块常用驱动栈。

## 快速使用

1. 把本目录推送到 GitHub 仓库。
2. 打开 GitHub 仓库的 `Actions`。
3. 运行 `Build ImmortalWrt M28C`。
4. 默认 `immortalwrt_ref` 为 `openwrt-25.12`；也可以填 `v25.12.0-rc2`、`master` 或其它上游分支/标签。
5. 编译完成后，在 workflow 的 Artifacts 里下载固件。

## 默认内容

默认 profile 在 `profiles/m28c/`：

- `target.config`：M28C 目标、ccache、PWM 风扇内核模块。
- `packages.txt`：插件和驱动包清单。

默认第三方来源：

- `feeds/third-party.feeds`：momo、QModem feed。
- `feeds/package-sources.conf`：sbwml MosDNS v5、v2ray-geodata、luci-app-fancontrol 源码包。

## 后期维护

加常规软件包：编辑 `profiles/m28c/packages.txt`，一行一个包名。禁用包名前面加 `-`，例如 `-luci-app-example`。

临时加包：运行 Actions 时填 `extra_packages`。

加第三方 feeds：编辑 `feeds/custom.feeds`，或运行 Actions 时填 `extra_feeds`。脚本会按 feed 名称和仓库 URL 跳过重复项。

本地源码编译插件：把 OpenWrt 包源码目录放到 `local-packages/<package-name>/`，目录里需要有 `Makefile`，然后把包名加到 `profiles/m28c/packages.txt`。

替换 `/etc`：把文件放进 `files/etc/`，例如 `files/etc/config/network` 会进入固件的 `/etc/config/network`。

替换 `/usr/bin`：把文件放进 `files/usr/bin/`。直接文件会复制并标记可执行；压缩包或目录会自动扫描并挑选最可能的 aarch64/arm64 Linux 可执行文件。

## 5G 和风扇

华为 MT5700-CN 相关默认包含 QMI、MBIM、NCM、Huawei NCM、ModemManager、QModem Next、USB 串口和 MHI/WWAN 驱动。刷入后可在 LuCI 的网络接口、ModemManager 或 QModem 页面配置 APN 和拨号方式。

M28C 上游 DTS 已声明 `pwm-fan`，设备包也带 `kmod-hwmon-pwmfan`。本项目额外加入 `luci-app-fancontrol`，通过内核 thermal trip points 控制风扇，避免直接抢写 PWM。

## 参考来源

- ImmortalWrt: https://github.com/immortalwrt/immortalwrt
- Momo: https://github.com/nikkinikki-org/OpenWrt-momo
- MosDNS LuCI: https://github.com/sbwml/luci-app-mosdns
- QModem: https://github.com/FUjr/QModem
- Fan Control: https://github.com/bigmalloy/luci-app-fancontrol
