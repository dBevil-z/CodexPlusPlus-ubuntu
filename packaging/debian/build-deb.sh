#!/usr/bin/env bash

set -euo pipefail

VERSION="${VERSION:-}"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-}"
PKG_RELEASE="${PKG_RELEASE:-1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
PKG_NAME="codex-plus-plus"
UPSTREAM_REPO_URL="https://github.com/BigPizzaV3/CodexPlusPlus.git"
SRC_DIR="${SRC_DIR:-${BUILD_DIR}/src}"
STAGE_DIR="${ROOT_DIR}/build/deb-root"
DIST_DIR="${ROOT_DIR}/dist"
TARBALL_PATH=""
UPSTREAM_URL=""

resolve_upstream_version() {
  if [[ -n "${UPSTREAM_VERSION}" ]]; then
    return
  fi

  UPSTREAM_VERSION="$(
    git ls-remote --tags "${UPSTREAM_REPO_URL}" 'refs/tags/v*' \
      | awk -F/ '/refs\/tags\/v[0-9]+\.[0-9]+\.[0-9]+$/ {print $3}' \
      | sed 's/^v//' \
      | sort -V \
      | tail -n1
  )"

  if [[ -z "${UPSTREAM_VERSION}" ]]; then
    echo "Failed to resolve the latest upstream version from ${UPSTREAM_REPO_URL}" >&2
    exit 1
  fi
}

resolve_package_metadata() {
  resolve_upstream_version
  VERSION="${VERSION:-${UPSTREAM_VERSION}-${PKG_RELEASE}}"
  TARBALL_PATH="${BUILD_DIR}/codex-plus-plus-${UPSTREAM_VERSION}.tar.gz"
  UPSTREAM_URL="https://github.com/BigPizzaV3/CodexPlusPlus/archive/refs/tags/v${UPSTREAM_VERSION}.tar.gz"
}

prepare_source() {
  install -dm755 "${BUILD_DIR}"
  if [[ ! -f "${TARBALL_PATH}" ]]; then
    curl -L --fail -o "${TARBALL_PATH}" "${UPSTREAM_URL}"
  fi

  rm -rf "${SRC_DIR}"
  mkdir -p "${SRC_DIR}"
  tar -xzf "${TARBALL_PATH}" -C "${SRC_DIR}" --strip-components=1

  patch -d "${SRC_DIR}" -Np1 -i "${ROOT_DIR}/packaging/aur/codex-plus-plus-plugin-unlock.patch"
  patch -d "${SRC_DIR}" -Np1 -i "${ROOT_DIR}/packaging/aur/codex-plus-plus-linux-port-fallback.patch"
}

build_launcher() {
  cargo build --release --locked -p codex-plus-launcher --manifest-path "${SRC_DIR}/Cargo.toml"
}

resolve_package_metadata
prepare_source
build_launcher

if [[ ! -x "${SRC_DIR}/target/release/codex-plus-plus" ]]; then
  echo "Build completed but launcher binary is missing: ${SRC_DIR}/target/release/codex-plus-plus" >&2
  exit 1
fi

rm -rf "${STAGE_DIR}"
install -dm755 \
  "${STAGE_DIR}/DEBIAN" \
  "${STAGE_DIR}/usr/bin" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/app" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/bin" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/upstream" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/webview" \
  "${STAGE_DIR}/usr/share/doc/${PKG_NAME}" \
  "${STAGE_DIR}/var/lib/${PKG_NAME}" \
  "${DIST_DIR}"

sed "s/@VERSION@/${VERSION}/g" \
  "${ROOT_DIR}/packaging/debian/control.in" \
  > "${STAGE_DIR}/DEBIAN/control"
install -Dm755 "${ROOT_DIR}/packaging/debian/postinst" "${STAGE_DIR}/DEBIAN/postinst"
install -Dm755 "${ROOT_DIR}/packaging/debian/prerm" "${STAGE_DIR}/DEBIAN/prerm"
install -Dm755 "${ROOT_DIR}/packaging/debian/postrm" "${STAGE_DIR}/DEBIAN/postrm"
install -Dm644 "${ROOT_DIR}/packaging/debian/triggers" "${STAGE_DIR}/DEBIAN/triggers"

install -Dm755 "${ROOT_DIR}/packaging/debian/codex-desktop-app-wrapper.sh" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/app/codex"
ln -s codex "${STAGE_DIR}/usr/lib/${PKG_NAME}/app/codex.exe"

install -Dm755 "${SRC_DIR}/target/release/codex-plus-plus" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/bin/codex-plus-plus-upstream"
install -Dm755 "${ROOT_DIR}/packaging/debian/codex-plus-plus.sh" \
  "${STAGE_DIR}/usr/bin/codex-plus-plus"
install -Dm644 "${ROOT_DIR}/packaging/aur/plugin-auth-unlocked.js" \
  "${STAGE_DIR}/usr/lib/${PKG_NAME}/webview/plugin-auth-unlocked.js"

ln -s /usr/bin/codex-plus-plus "${STAGE_DIR}/usr/lib/${PKG_NAME}/bin/codex-desktop-injected"
ln -s codex-plus-plus "${STAGE_DIR}/usr/bin/codexplusplus"

install -Dm644 "${SRC_DIR}/README.md" "${STAGE_DIR}/usr/share/doc/${PKG_NAME}/README.md"
install -Dm644 "${ROOT_DIR}/packaging/debian/README.Debian" \
  "${STAGE_DIR}/usr/share/doc/${PKG_NAME}/README.Debian"
gzip -n -9 "${STAGE_DIR}/usr/share/doc/${PKG_NAME}/README.md"
gzip -n -9 "${STAGE_DIR}/usr/share/doc/${PKG_NAME}/README.Debian"

find "${STAGE_DIR}" -type d -exec chmod 755 {} +
dpkg-deb --build --root-owner-group "${STAGE_DIR}" \
  "${DIST_DIR}/${PKG_NAME}_${VERSION}_amd64.deb"
