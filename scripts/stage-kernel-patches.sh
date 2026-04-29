#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

OPENWRT_DIR="${1:-${OPENWRT_DIR:-}}"
[ -n "$OPENWRT_DIR" ] || die "Usage: $0 <openwrt-dir>"
need_dir "$OPENWRT_DIR"

PROJECT_DIR="${PROJECT_DIR:-$(project_dir)}"
kernel_patchver="$(
  awk -F ':=' '/^KERNEL_PATCHVER:=/ { print $2; exit }' "$OPENWRT_DIR/target/linux/rockchip/Makefile"
)"
[ -n "$kernel_patchver" ] || die "Unable to detect rockchip KERNEL_PATCHVER"

stage_patches() {
  local src="$1"
  local dst="$2"
  local fallback="${3:-}"

  [ -d "$src" ] || return 0

  if [ ! -d "$dst" ] && [ -n "$fallback" ]; then
    dst="$fallback"
  fi
  need_dir "$dst"

  log "Staging kernel patches into ${dst#$OPENWRT_DIR/}"
  rsync -a --include='*.patch' --exclude='*' "$src"/ "$dst"/
}

stage_patches \
  "$PROJECT_DIR/patches/kernel/generic" \
  "$OPENWRT_DIR/target/linux/generic/hack-$kernel_patchver" \
  "$OPENWRT_DIR/target/linux/generic/hack"

stage_patches \
  "$PROJECT_DIR/patches/kernel/rockchip" \
  "$OPENWRT_DIR/target/linux/rockchip/patches-$kernel_patchver"
