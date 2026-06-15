# CodexPlusPlus Ubuntu Package

This repository packages [BigPizzaV3/CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus)
for the Ubuntu `codex-desktop` layout:

- `/usr/bin/codex-desktop`
- `/opt/codex-desktop/start.sh`

The packaging is based on the Arch AUR package
`codex-plus-plus`, then adapted for Debian/Ubuntu.

Prebuilt `.deb` files can be generated locally from this repository. The GitHub
repository itself keeps the packaging source and build instructions.

## Repository Layout

- `packaging/debian/`: Debian package metadata, wrapper scripts, and the build script
- `packaging/aur/`: AUR-derived patches and webview asset used during packaging
- `dist/`: local build output directory used by `build-deb.sh`

## Build

Requirements:

- `cargo`
- `patch`
- `curl`
- `dpkg-deb`

Build the package:

```bash
bash ./packaging/debian/build-deb.sh
```

The script will:

1. download `BigPizzaV3/CodexPlusPlus` `v1.2.4`
2. apply the AUR patch set
3. build the Rust launcher
4. assemble `codex-plus-plus_1.2.4-1_amd64.deb`

## Install

```bash
sudo apt install ./dist/codex-plus-plus_1.2.4-1_amd64.deb
```

Useful commands after installation:

```bash
sudo codex-plus-plus status
sudo codex-plus-plus disable
sudo codex-plus-plus enable
```
