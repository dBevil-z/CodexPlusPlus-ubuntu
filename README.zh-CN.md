# CodexPlusPlus Ubuntu 打包仓库

[English](./README.md)

这是 [BigPizzaV3/CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus)
在 Ubuntu / Debian 下的打包仓库，适配当前 Linux `codex-desktop` 的安装布局：

- `/usr/bin/codex-desktop`
- `/opt/codex-desktop/start.sh`

仓库中保存了 Debian 打包脚本、从 AUR 继承并调整的补丁，以及本地构建
`.deb` 所需的辅助文件。

## 特性

- 基于 Arch AUR `codex-plus-plus` 打包思路改造成 Debian/Ubuntu 版本
- 适配 Ubuntu `codex-desktop` 目录结构的启动包装和注入脚本
- 可重复构建：默认自动获取上游最新稳定 tag、打补丁、编译 launcher、生成 `.deb`

## 快速开始

构建：

```bash
bash ./packaging/debian/build-deb.sh
```

安装：

```bash
sudo apt install ./dist/codex-plus-plus_*_amd64.deb
```

管理注入状态：

```bash
sudo codex-plus-plus status
sudo codex-plus-plus disable
sudo codex-plus-plus enable
```

## 依赖

- `cargo`
- `patch`
- `curl`
- `dpkg-deb`

## 构建流程

构建脚本会依次完成：

1. 自动解析上游最新稳定 `v*` tag
2. 应用仓库内附带的 AUR 补丁
3. 以 release 模式编译 Rust launcher
4. 生成 `codex-plus-plus_<upstream>-<pkgrel>_amd64.deb`

构建产物会输出到 [`dist/`](./dist/) 目录。

如果你想固定到某个上游版本，而不是默认取最新版本：

```bash
UPSTREAM_VERSION=1.2.8 bash ./packaging/debian/build-deb.sh
```

如果你想手动指定 Debian 包版本号：

```bash
VERSION=1.2.8-2 bash ./packaging/debian/build-deb.sh
```

## 仓库结构

- `packaging/debian/`：Debian 控制文件、维护脚本、wrapper 和构建脚本
- `packaging/aur/`：从 AUR 继承的补丁和 webview 覆盖资源
- `dist/`：本地生成 `.deb` 时使用的输出目录

## 说明

- 安装后会将 `/usr/bin/codex-desktop` 替换为 Codex++ 启动入口，并把原始入口
  备份到 `/usr/lib/codex-plus-plus/upstream/`。
- 当前 wrapper 针对的是 Ubuntu / Linux 版 Codex Desktop 的现有布局，实际复用
  `/opt/codex-desktop/start.sh` 来启动桌面应用。
