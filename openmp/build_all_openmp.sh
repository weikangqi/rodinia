#!/bin/bash
set -euo pipefail
# Build all OpenMP benchmarks, save build logs, and collect executables under openmp/build-android
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build-android"
LOG_DIR="$BUILD_DIR/logs"
REMOTE_TMP="/data/local/tmp"

mkdir -p "$BUILD_DIR" "$LOG_DIR"

# Benchmarks to skip (edit as needed)
SKIP=("_bilateral")

echo "Building OpenMP benchmarks under $ROOT_DIR"
for d in "$ROOT_DIR"/*; do
  [ -d "$d" ] || continue
  bench=$(basename "$d")
  if [[ " ${SKIP[*]} " =~ " $bench " ]]; then
    echo "Skipping $bench"
    continue
  fi
  if [ ! -f "$d/Makefile" ]; then
    echo "No Makefile in $bench, skipping"
    continue
  fi

  echo "== Building $bench =="
  build_log="$LOG_DIR/build_${bench}.log"
  (cd "$d" && make clean >/dev/null 2>&1 || true)
  if (cd "$d" && make) >"$build_log" 2>&1; then
    echo "Build succeeded: $bench (log -> $build_log)"
  else
    echo "Build failed: $bench (see $build_log)"
    continue
  fi

  # Collect executables (recursively), only ELF files with exec bit
  found=0
  while IFS= read -r exe; do
    [ -z "$exe" ] && continue
    # verify ELF
    if file -b "$exe" | grep -qi elf; then
      name=$(basename "$exe")
      out_dir="$BUILD_DIR/$bench"
      mkdir -p "$out_dir"
      out="$out_dir/$name"
      cp "$exe" "$out" || true
      chmod +x "$out" || true
      echo "Collected executable -> $out"
      found=1
    fi
  done < <(find "$d" -type f -perm -111 -print 2>/dev/null)

  if [ $found -eq 0 ]; then
    echo "No executable found for $bench"
  fi
done

echo "All done. Build logs: $LOG_DIR; executables: $BUILD_DIR"
