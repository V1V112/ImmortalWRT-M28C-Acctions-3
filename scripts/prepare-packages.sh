#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

OPENWRT_DIR="${1:-${OPENWRT_DIR:-}}"
[ -n "$OPENWRT_DIR" ] || die "Usage: $0 <openwrt-dir>"
need_dir "$OPENWRT_DIR"

PROJECT_DIR="${PROJECT_DIR:-$(project_dir)}"
PACKAGE_SOURCES="$PROJECT_DIR/feeds/package-sources.conf"

CUSTOM_DIR="$OPENWRT_DIR/package/custom"
LOCAL_DIR="$OPENWRT_DIR/package/local"
mkdir -p "$CUSTOM_DIR" "$LOCAL_DIR"

remove_if_exists() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    rm -rf "$path"
    log "Removed conflicting package path: ${path#$OPENWRT_DIR/}"
  fi
}

remove_feed_package_defs() {
  local package_name="$1"
  local search_root makefile package_dir

  for search_root in "$OPENWRT_DIR/feeds" "$OPENWRT_DIR/package/feeds"; do
    [ -d "$search_root" ] || continue

    while IFS= read -r -d '' makefile; do
      grep -Eq "^(PKG_NAME:=${package_name}|define Package/${package_name}([[:space:]/]|$))" "$makefile" || continue
      package_dir="$(dirname "$makefile")"
      remove_if_exists "$package_dir"
    done < <(find "$search_root" -name Makefile -type f -print0)
  done
}

log "Removing built-in packages replaced by third-party sources"
remove_if_exists "$OPENWRT_DIR/feeds/packages/net/mosdns"
remove_if_exists "$OPENWRT_DIR/feeds/packages/net/v2ray-geodata"
remove_if_exists "$OPENWRT_DIR/package/feeds/packages/mosdns"
remove_if_exists "$OPENWRT_DIR/package/feeds/packages/v2ray-geodata"
remove_feed_package_defs mosdns
remove_feed_package_defs v2ray-geodata
remove_feed_package_defs v2ray-geoip
remove_feed_package_defs v2ray-geosite

clone_package_source() {
  local name="$1"
  local repo="$2"
  local ref="$3"
  local dest_rel="$4"
  local subdir="$5"
  local clone_dir="$tmp_dir/$name"
  local dest="$OPENWRT_DIR/$dest_rel"
  local src

  log "Cloning package source: $name ($ref)"
  git clone --depth 1 --filter=blob:none --branch "$ref" "$repo" "$clone_dir"

  if [ "$subdir" = "." ]; then
    src="$clone_dir"
  else
    src="$clone_dir/$subdir"
  fi

  need_dir "$src"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  rsync -a --delete --exclude='.git' "$src"/ "$dest"/
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

if [ -f "$PACKAGE_SOURCES" ]; then
  while read -r name repo ref dest subdir rest; do
    case "${name:-}" in
      ""|\#*) continue ;;
    esac

    [ -z "${rest:-}" ] || die "Too many columns in $PACKAGE_SOURCES line for $name"
    [ -n "${repo:-}" ] && [ -n "${ref:-}" ] && [ -n "${dest:-}" ] && [ -n "${subdir:-}" ] \
      || die "Invalid package source line for $name"

    clone_package_source "$name" "$repo" "$ref" "$dest" "$subdir"
  done < "$PACKAGE_SOURCES"
fi

log "Copying local package sources"
shopt -s nullglob dotglob

copy_local_package() {
  local pkg="$1"
  local base

  base="$(basename "$pkg")"
  rm -rf "$LOCAL_DIR/$base"
  rsync -a --delete --exclude='.git' "$pkg"/ "$LOCAL_DIR/$base"/
  log "Copied local package: package/local/$base"
}

for pkg in "$PROJECT_DIR"/local-packages/*; do
  base="$(basename "$pkg")"
  case "$base" in
    .gitkeep|README.md) continue ;;
  esac

  if [ -d "$pkg" ]; then
    if [ -f "$pkg/Makefile" ]; then
      copy_local_package "$pkg"
      continue
    fi

    copied_nested=0
    for nested_pkg in "$pkg"/*; do
      [ -d "$nested_pkg" ] || continue
      [ -f "$nested_pkg/Makefile" ] || continue
      copy_local_package "$nested_pkg"
      copied_nested=1
    done

    [ "$copied_nested" -eq 1 ] || die "No Makefile found in local package directory: $pkg"
  else
    warn "Ignoring non-directory local package item: $pkg"
  fi
done

log "Prepared custom package sources under package/custom and package/local"
