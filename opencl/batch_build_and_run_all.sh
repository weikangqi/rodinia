#!/bin/bash
# 批量编译 opencl 下所有 benchmark，推送到设备并运行，拉回日志
# 运行目录: /root/rodinia/opencl
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build-android"
LOG_DIR="$BUILD_DIR/logs"
REMOTE_TMP="/data/local/tmp"
NDK="${ANDROID_NDK_HOME:-}"

mkdir -p "$BUILD_DIR" "$LOG_DIR"

# ensure libOpenCL exists locally
if [ ! -f "$ROOT_DIR/build-android/lib/libOpenCL.so" ]; then
  mkdir -p "$ROOT_DIR/build-android/lib"
  adb pull /vendor/lib64/libOpenCL.so "$ROOT_DIR/build-android/lib/" || true
fi

# push libc++_shared if missing on device
push_libcxx() {
  if adb shell test -f "$REMOTE_TMP/libc++_shared.so" >/dev/null 2>&1; then
    return
  fi
  if [ -z "$NDK" ]; then
    echo "WARN: ANDROID_NDK_HOME not set; skip pushing libc++_shared" >&2
    return
  fi
  src="$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"
  if [ -f "$src" ]; then
    adb push "$src" "$REMOTE_TMP/" >/dev/null || true
  else
    echo "WARN: 未找到 libc++_shared.so at $src" >&2
  fi
}

# skip these dirs and benchmarks (edit here to change skip list)
SKIP=("_CL_headers" "build-android" "leukocyte")

for d in "$ROOT_DIR"/*; do
  [ -d "$d" ] || continue
  bench=$(basename "$d")
  if [[ " ${SKIP[*]} " =~ " $bench " ]]; then
    continue
  fi
  # only process if has Makefile
  if [ ! -f "$d/Makefile" ]; then
    echo "跳过 $bench（无 Makefile）"
    continue
  fi

  echo "==== 编译 $bench ===="
  build_log="$LOG_DIR/build_${bench}.log"
  (cd "$d" && make clean >/dev/null 2>&1 || true)
  if ! (cd "$d" && make) >"$build_log" 2>&1; then
    echo "编译 $bench 失败，详见 $build_log"
    continue
  fi
  echo "编译 $bench 成功"

  # 递归查找可执行文件（优先使用构建产物，不限于顶层），并避免在 build 目录中出现同名冲突
  exe_path=$(find "$d" -type f -perm -111 -print | head -n1 || true)
  # 备用：若不存在可执行，则尝试以目录名为文件名的可执行文件
  if [ -z "$exe_path" ]; then
    if [ -x "$d/$bench" ]; then
      exe_path="$d/$bench"
    fi
  fi
  if [ -z "$exe_path" ]; then
    echo "未找到 $bench 可执行，跳过运行"
    continue
  fi
  exe=$(basename "$exe_path")
  echo "找到可执行: $exe_path"

  # 将可执行拷贝到 build 目录并加上 bench 前缀以避免冲突
  build_exe="$BUILD_DIR/${bench}__${exe}"
  cp "$exe_path" "$build_exe"

  # 推必要文件
  push_libcxx
  # 在设备上使用原始可执行名（不带前缀），因此推送时重命名为 $exe
  adb push "$build_exe" "$REMOTE_TMP/$exe" >/dev/null || true
  adb shell chmod 755 "$REMOTE_TMP/$exe" || true

  if [ -f "$d/Kernels.cl" ]; then
    adb push "$d/Kernels.cl" "$REMOTE_TMP/" >/dev/null || true
  fi

  # push data files if exist
  if [ -d "$ROOT_DIR/../data/$bench" ]; then
    for f in "$ROOT_DIR/../data/$bench"/*; do
      [ -e "$f" ] || continue
      adb push "$f" "$REMOTE_TMP/" >/dev/null || true
    done
  fi

  # determine run args: if data exists, use first file name, else none
  run_args=""
  if adb shell ls "$REMOTE_TMP"/ | grep -q "\b"$bench"\b" >/dev/null 2>&1; then
    :
  fi
  # try to pick an input file from device matching data/<bench> filenames
  first_data=$(ls -1 "$ROOT_DIR/../data/$bench" 2>/dev/null | head -n1 || true)
  if [ -n "$first_data" ]; then
    run_args="/data/local/tmp/$first_data"
  fi

  remote_log="$REMOTE_TMP/${bench}.run.log"
  echo "在设备上运行 $exe $run_args -> $remote_log"
  adb shell sh -c "LD_LIBRARY_PATH=$REMOTE_TMP:\$LD_LIBRARY_PATH $REMOTE_TMP/$exe $run_args > $remote_log 2>&1" || true
  adb pull "$remote_log" "$LOG_DIR/" >/dev/null || true
  echo "日志拉取到 $LOG_DIR/${bench}.run.log"
done

echo "批量处理完成，日志在 $LOG_DIR"