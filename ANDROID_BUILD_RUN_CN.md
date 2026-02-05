# Android 编译与运行说明（OpenMP，arm64-v8a）

本文档说明如何使用 Android NDK 为 arm64-v8a 交叉编译 Rodinia 的 OpenMP 基准，并在设备上通过 `adb` 运行与采集日志。

## 前提条件

- 设置环境变量 `ANDROID_NDK_HOME`（示例：`/root/code/fork/ndks/android-ndk-r29`）。
- 设备可达并授权：`adb connect <device>` 或 `adb devices`。
- 当前工作目录在仓库根目录（包含 `opencl/`、`openmp/`）。

## 目录说明

- OpenMP 源码：`openmp/`
- 构建与运行产物（脚本生成）：
  - OpenMP：`openmp/build-android/`

## OpenMP：批量编译

脚本：`openmp/build_all_openmp.sh`

```bash
cd openmp
./build_all_openmp.sh
```

产出：
- 编译日志：`openmp/build-android/logs/build_<bench>.log`
- 可执行文件：`openmp/build-android/<bench>/<exe>`（按基准名分目录保存）

> 说明：脚本会递归查找可执行并收集到 `openmp/build-android/<bench>/`。

## 在设备上运行（示例：`bfs`）

1) 推送输入数据：

```bash
adb push data/bfs/graph1M.txt /data/local/tmp/bfs.input
```

2) 推送可执行文件：

```bash
adb push openmp/build-android/bfs/bfs /data/local/tmp/bfs
adb shell chmod 755 /data/local/tmp/bfs
```

3) 运行并抓取日志：

```bash
adb shell 'export LD_LIBRARY_PATH=/data/local/tmp; /data/local/tmp/bfs /data/local/tmp/bfs.input > /data/local/tmp/bfs.run.full.log 2>&1; echo EXIT:$? > /data/local/tmp/bfs.exitcode'
adb pull /data/local/tmp/bfs.run.full.log openmp/build-android/logs/
adb pull /data/local/tmp/bfs.exitcode openmp/build-android/logs/
```

## 运行时库（常见问题）

- 若报错 `CANNOT LINK EXECUTABLE ... libc++_shared.so not found`：

```bash
adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so /data/local/tmp/
```

- 若 OpenMP 报错 `libomp.so not found`：

```bash
adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/21/lib/linux/aarch64/libomp.so /data/local/tmp/
```

## 备注

- 运行日志默认保存在 `openmp/build-android/logs/` 与 `opencl/build-android/logs/`。
- 若需要运行其他基准，参考其 `run` 脚本或 Makefile 中的输入参数说明。
