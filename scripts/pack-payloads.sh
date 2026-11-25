#!/usr/bin/env bash
# Pack all scripts/ghostlock/*.sh into Unix-LF tarballs under scripts/ghostlock/out/
# ready to pass to GhostLock's root.sh.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/ghostlock"
OUT_DIR="$SRC_DIR/out"
STAGE_DIR="$OUT_DIR/_stage"

mkdir -p "$OUT_DIR"

for f in "$SRC_DIR"/*.sh; do
  base="$(basename "$f")"
  name="$(basename "$f" .sh)"
  tar_path="$OUT_DIR/$name.tar"
  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"
  tr -d '\r' < "$f" > "$STAGE_DIR/$base"
  chmod 755 "$STAGE_DIR/$base"
  tar -C "$STAGE_DIR" -cf "$tar_path" "$base"
  echo "Packed $tar_path"
done

rm -rf "$STAGE_DIR"
