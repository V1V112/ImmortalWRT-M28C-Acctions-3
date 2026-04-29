#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

OPENWRT_DIR="${1:-${OPENWRT_DIR:-}}"
[ -n "$OPENWRT_DIR" ] || die "Usage: $0 <openwrt-dir>"
need_dir "$OPENWRT_DIR"

PROJECT_DIR="${PROJECT_DIR:-$(project_dir)}"
PATCH_SRC="$PROJECT_DIR/patches/kernel/generic"

[ -d "$PATCH_SRC" ] || exit 0

kernel_patchver="$(
  awk -F ':=' '/^KERNEL_PATCHVER:=/ { print $2; exit }' "$OPENWRT_DIR/target/linux/rockchip/Makefile"
)"
[ -n "$kernel_patchver" ] || die "Unable to detect rockchip KERNEL_PATCHVER"

PATCH_DST="$OPENWRT_DIR/target/linux/generic/hack-$kernel_patchver"
if [ ! -d "$PATCH_DST" ]; then
  PATCH_DST="$OPENWRT_DIR/target/linux/generic/hack"
fi
need_dir "$PATCH_DST"

log "Staging kernel patches into ${PATCH_DST#$OPENWRT_DIR/}"
rsync -a --include='*.patch' --exclude='*' "$PATCH_SRC"/ "$PATCH_DST"/
