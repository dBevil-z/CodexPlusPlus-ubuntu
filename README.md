# CodexPlusPlus Ubuntu Package

[简体中文](./README.zh-CN.md)

Ubuntu/Debian packaging for [BigPizzaV3/CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus),
adapted for the Linux `codex-desktop` layout:

- `/usr/bin/codex-desktop`
- `/opt/codex-desktop/start.sh`

This repository keeps the packaging source, AUR-derived patches, and build
scripts needed to generate a local `.deb` package.

## Highlights

- Debian packaging adapted from the Arch AUR `codex-plus-plus` package
- Wrapper scripts tailored for the Ubuntu `codex-desktop` installation layout
- Reproducible local build flow that resolves the latest upstream stable tag,
  patches it, builds the launcher, and assembles a `.deb`

## Quick Start

Build:

```bash
bash ./packaging/debian/build-deb.sh
```

Install:

```bash
sudo apt install ./dist/codex-plus-plus_*_amd64.deb
```

Manage injection:

```bash
sudo codex-plus-plus status
sudo codex-plus-plus disable
sudo codex-plus-plus enable
```

## Requirements

- `cargo`
- `patch`
- `curl`
- `dpkg-deb`

## Build Flow

The build script will:

1. Resolve the latest upstream stable `v*` tag
2. Apply the bundled AUR patch set
3. Build the Rust launcher in release mode
4. Assemble `codex-plus-plus_<upstream>-<pkgrel>_amd64.deb`

Build output is written to [`dist/`](./dist/).

To pin a specific upstream release instead of the latest one:

```bash
UPSTREAM_VERSION=1.2.8 bash ./packaging/debian/build-deb.sh
```

To override the Debian package version string explicitly:

```bash
VERSION=1.2.8-2 bash ./packaging/debian/build-deb.sh
```

## Repository Layout

- `packaging/debian/`: Debian control files, maintainer scripts, wrappers, and build script
- `packaging/aur/`: AUR-derived patches and the webview override asset
- `dist/`: local output directory for generated package artifacts

## Notes

- The package replaces `/usr/bin/codex-desktop` with the Codex++ launcher and
  keeps a backup under `/usr/lib/codex-plus-plus/upstream/`.
- The wrapper is written for the current Ubuntu/Linux Codex Desktop layout and
  reuses `/opt/codex-desktop/start.sh`.
