**编译与运行（Android - OpenCL，arm64-v8a）**

本文档说明如何使用 Android NDK 为 arm64-v8a 交叉编译 Rodinia 的 OpenCL 基准并在设备上通过 `adb` 运行与采集日志。

**前提**
- 环境变量 `ANDROID_NDK_HOME` 指向 NDK（示例：/root/code/fork/ndks/android-ndk-r29）。
- 设备可达并授权：`adb connect <device>` 或 `adb devices`。
- 已在项目根目录（含 `opencl/`）下工作。

**主要目录**
- OpenCL 源：`opencl/`
- 构建与运行产物、日志：`opencl/build-android/`（脚本使用该目录存放二进制与日志）

**快速一键（批量）构建并运行**
仓库包含批量脚本：`opencl/batch_build_and_run_all.sh`。该脚本会：
- 在每个 benchmark 目录执行 `make`（跳过无 Makefile 的目录或在 `SKIP` 列表中的目录）。
- 递归查找构建出的可执行，拷贝到 `opencl/build-android/`（脚本会以 `bench__exe` 前缀避免冲突），将二进制推到设备并运行。

运行示例：
```bash
cd opencl
./batch_build_and_run_all.sh
```

运行后日志保存在：`opencl/build-android/logs/`，每个 benchmark 会生成 `build_<bench>.log`（编译日志）和 `<bench>.run.log`（设备运行日志）。

**单个 benchmark 构建与运行（示例：`gaussian`）**
1. 进入 benchmark 目录并构建：
```bash
cd opencl/gaussian
make clean && make
```
2. 将可执行推到设备并运行（脚本中会做这些步骤；手动操作示例）：
```bash
# 确保设备上有 C++ 运行时（仅当 binary 使用 libc++ 时）
adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so /data/local/tmp/

# 将可执行推到设备
adb push ./gaussian /data/local/tmp/gaussian
adb shell chmod 755 /data/local/tmp/gaussian

# 将内核文件或数据推送到设备（若需要）
adb push gaussianElim_kernels.cl /data/local/tmp/
adb push data/gaussian/matrix4.txt /data/local/tmp/

# 在设备上以 LD_LIBRARY_PATH 指定运行时位置并运行
adb shell "LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/gaussian /data/local/tmp/matrix4.txt"
```

运行结果与日志：
- 将 stdout/stderr 重定向到设备上的日志文件：`/data/local/tmp/<bench>.run.log`，然后用 `adb pull` 拉回到 `opencl/build-android/logs/`。

**脚本行为要点（便于调试）**
- `batch_build_and_run_all.sh` 会尝试从设备拉取 `/vendor/lib64/libOpenCL.so` 到 `opencl/build-android/lib/`，以便在主机上链接（如果可用）。
- 脚本会把 `libc++_shared.so` 推到 `/data/local/tmp/`（若设备缺失）。
- 脚本默认只选择每个 benchmark 下的第一个可执行文件；已更新为递归查找并以 `bench__exe` 命名拷贝到 `build-android`，再推送到设备上以原始可执行名运行，避免同名冲突。

**常见问题与解决办法**
- 设备报错 `CANNOT LINK EXECUTABLE` 指出 `libc++_shared.so` 架构不匹配：检查你推送的 `libc++_shared.so` 是否为 aarch64（NDK 中路径为 `.../sysroot/usr/lib/aarch64-linux-android/libc++_shared.so`）。
- 若脚本没有拷到二进制：检查该 benchmark 的 `Makefile` 是否将目标放在子目录或没有设置可执行位。可以手动或修改 Makefile 将产物放回顶层，或使用递归查找脚本（已在批量脚本中处理）。

**调试命令（快速）**
```bash
# 列出仓库中所有 ELF 可执行（带可执行位）
find opencl -type f -exec sh -c 'file -b "$1" | grep -qi elf && [ -x "$1" ] && echo "$1"' _ {} \;

# 查看 build-android 下的内容
ls -l opencl/build-android/

# 拉回设备上的日志到本地
adb pull /data/local/tmp/<bench>.run.log opencl/build-android/logs/
```

如果你希望我把这份说明放到仓库里其他位置或加上 CI 友好的打包/压缩命令（例如把 `opencl/build-android/` 打包成 zip），告诉我需要的格式，我会继续补充。

---
文件创建于项目根目录：`BUILD_ANDROID_CN.md`。
