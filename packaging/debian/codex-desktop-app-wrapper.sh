#!/usr/bin/env bash

set -euo pipefail

APPDIR="${CODEXPP_CODEX_DESKTOP_DIR:-/opt/codex-desktop}"
START_SH="${APPDIR}/start.sh"
WEBVIEW_DIR="${APPDIR}/content/webview"
PLUGIN_AUTH_UNLOCK_FILE="${CODEXPP_PLUGIN_AUTH_UNLOCK_FILE:-/usr/lib/codex-plus-plus/webview/plugin-auth-unlocked.js}"
SHADOW_DIR=""
START_PID=""

cleanup() {
  local status=$?

  if [[ -n "${START_PID}" ]] && kill -0 "${START_PID}" 2>/dev/null; then
    kill "${START_PID}" 2>/dev/null || true
    wait "${START_PID}" 2>/dev/null || true
  fi

  if [[ -n "${SHADOW_DIR}" ]]; then
    rm -rf "${SHADOW_DIR}"
  fi

  exit "${status}"
}

forward_signal() {
  local sig="$1"

  if [[ -n "${START_PID}" ]] && kill -0 "${START_PID}" 2>/dev/null; then
    kill -"${sig}" "${START_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT
trap 'forward_signal HUP' HUP
trap 'forward_signal INT' INT
trap 'forward_signal TERM' TERM

require_codex_desktop() {
  if [[ ! -d "${APPDIR}" ]]; then
    echo "Codex Desktop app directory not found: ${APPDIR}" >&2
    exit 1
  fi

  if [[ ! -x "${START_SH}" ]]; then
    echo "Codex Desktop launcher not found or not executable: ${START_SH}" >&2
    exit 1
  fi

  if [[ ! -d "${WEBVIEW_DIR}" ]]; then
    echo "Codex Desktop webview directory not found: ${WEBVIEW_DIR}" >&2
    exit 1
  fi
}

link_app_tree() {
  local entry
  local name

  shopt -s dotglob nullglob
  for entry in "${APPDIR}"/*; do
    name="$(basename "${entry}")"
    case "${name}" in
      .|..|content|start.sh)
        continue
        ;;
    esac
    ln -s "${entry}" "${SHADOW_DIR}/${name}"
  done
  shopt -u dotglob nullglob

  install -dm755 "${SHADOW_DIR}/content"
  shopt -s nullglob
  for entry in "${APPDIR}/content"/*; do
    name="$(basename "${entry}")"
    [[ "${name}" == "webview" ]] && continue
    ln -s "${entry}" "${SHADOW_DIR}/content/${name}"
  done
  shopt -u nullglob

  install -Dm755 "${START_SH}" "${SHADOW_DIR}/start.sh"
}

create_patched_webview_dir() {
  local entry
  local name
  local replaced_plugin_auth=0
  local plugin_auth_assets=()

  install -dm755 "${SHADOW_DIR}/content/webview"

  shopt -s nullglob
  for entry in "${WEBVIEW_DIR}"/*; do
    name="$(basename "${entry}")"
    [[ "${name}" == "assets" ]] && continue
    ln -s "${entry}" "${SHADOW_DIR}/content/webview/${name}"
  done

  plugin_auth_assets=("${WEBVIEW_DIR}/assets"/plugin-auth-*.js)
  if ((${#plugin_auth_assets[@]} == 0)); then
    ln -s "${WEBVIEW_DIR}/assets" "${SHADOW_DIR}/content/webview/assets"
    shopt -u nullglob
    echo "Codex++ note: no plugin-auth-*.js asset found to replace; continuing with renderer injection only." >&2
    return
  fi

  if [[ ! -f "${PLUGIN_AUTH_UNLOCK_FILE}" ]]; then
    ln -s "${WEBVIEW_DIR}/assets" "${SHADOW_DIR}/content/webview/assets"
    shopt -u nullglob
    echo "Codex++ note: plugin auth assets exist but unlock file is missing: ${PLUGIN_AUTH_UNLOCK_FILE}" >&2
    return
  fi

  install -dm755 "${SHADOW_DIR}/content/webview/assets"
  for entry in "${WEBVIEW_DIR}/assets"/*; do
    name="$(basename "${entry}")"
    if [[ "${name}" == plugin-auth-*.js ]]; then
      ln -s "${PLUGIN_AUTH_UNLOCK_FILE}" "${SHADOW_DIR}/content/webview/assets/${name}"
      replaced_plugin_auth=1
    else
      ln -s "${entry}" "${SHADOW_DIR}/content/webview/assets/${name}"
    fi
  done
  shopt -u nullglob

  (( replaced_plugin_auth == 1 ))
}

require_codex_desktop
SHADOW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-plus-plus-app.XXXXXX")"
link_app_tree
create_patched_webview_dir

"${SHADOW_DIR}/start.sh" "$@" &
START_PID="$!"
wait "${START_PID}"
START_PID=""
