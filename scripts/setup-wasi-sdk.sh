#!/usr/bin/env bash
#
# Download wasi-sdk (clang + WASI sysroot) for the current OS/arch.
# Invoked by `lgx setup-wasi-sdk`. Installs to $WASI_SDK_PATH (default
# ~/wasi-sdk). One-time setup; needed only to (re)build resources/sqlite3.wasm.
#
# (The asdf/mise wasi-sdk plugin is not used: it builds a non-arch, pre-v25
# asset URL that 404s on current releases and never supported arm64.)
set -euo pipefail

VER="${WASI_SDK_VERSION:-33}"
DEST="${WASI_SDK_PATH:-$HOME/wasi-sdk}"

case "$(uname -m)" in
  aarch64 | arm64) arch=arm64 ;;
  x86_64 | amd64) arch=x86_64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac
case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=macos ;;
  *) echo "unsupported os: $(uname -s)" >&2; exit 1 ;;
esac

url="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${VER}/wasi-sdk-${VER}.0-${arch}-${os}.tar.gz"
echo "downloading $url"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/wasi-sdk.tar.gz" "$url"
mkdir -p "$DEST"
tar xzf "$tmp/wasi-sdk.tar.gz" -C "$DEST" --strip-components=1
echo "wasi-sdk $VER installed to $DEST"
"$DEST/bin/clang" --version | head -1
