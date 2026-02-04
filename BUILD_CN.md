# Rodinia Benchmark 编译与运行指南

本文档介绍如何在 ARM64 (Rockchip RK3588) 平台上编译和运行 Rodinia Benchmark 的 OpenMP 和 OpenCL 版本。

## 目录

- [环境要求](#环境要求)
- [OpenMP 编译](#openmp-编译)
- [OpenCL 编译](#opencl-编译)
- [运行程序](#运行程序)
- [常见问题](#常见问题)

---

## 环境要求

### 系统要求
- **操作系统**: Ubuntu 22.04 (或类似的 Linux 发行版)
- **架构**: ARM64 (aarch64)
- **设备**: Rockchip RK3588 或类似开发板

### 依赖包

```bash
# 更新包列表
sudo apt update

# 安装基础编译工具
sudo apt install -y build-essential gcc g++ make git

# 安装 OpenMP 支持 (通常包含在 gcc 中)
sudo apt install -y libgomp1

# 安装 OpenCL 支持
sudo apt install -y opencl-headers ocl-icd-libopencl1

# 创建 OpenCL 库符号链接
sudo ln -sf /usr/lib/aarch64-linux-gnu/libOpenCL.so.1 \
           /usr/lib/aarch64-linux-gnu/libOpenCL.so

# 可选：安装 Mali OpenCL 驱动
sudo apt install -y mali-opencl-headers
```

---

## OpenMP 编译

### 编译所有程序

```bash
cd ~/rodinia/openmp
make
```

### 编译单个程序

```bash
cd ~/rodinia/openmp/<程序名>
make
```

**示例**:
```bash
cd ~/rodinia/openmp/bfs
make
```

### 清理编译产物

```bash
# 清理单个程序
cd ~/rodinia/openmp/bfs
make clean

# 清理所有 OpenMP 程序
cd ~/rodinia/openmp
make clean
```

### 已成功编译的程序 (19个)

| 程序 | �述 |
|------|------|
| [backprop](openmp/backprop/) | 反向传播神经网络 |
| [bfs](openmp/bfs/) | 广度优先搜索 |
| [b+tree](openmp/b%2Btree/) | B+树 |
| [cfd](openmp/cfd/) | 计算流体动力学 |
| [heartwall](openmp/heartwall/) | 心脏壁追踪 |
| [hotspot](openmp/hotspot/) | 热点计算 |
| [hotspot3D](openmp/hotspot3D/) | 3D 热点计算 |
| [kmeans](openmp/kmeans/) | K-means 聚类 |
| [lavaMD](openmp/lavaMD/) | 分子动力学 |
| [leukocyte](openmp/leukocyte/) | 白细胞追踪 |
| [lud](openmp/lud/) | LU 分解 |
| [myocyte](openmp/myocyte/) | 肌细胞模拟 |
| [nn](openmp/nn/) | 最近邻搜索 |
| [nw](openmp/nw/) | Needleman-Wunsch 序列比对 |
| [pathfinder](openmp/pathfinder/) | 路径查找 |
| [particlefilter](openmp/particlefilter/) | 粒子滤波 |
| [srad_v1](openmp/srad_v1/) | 斑点降低各向异性扩散 v1 |
| [srad_v2](openmp/srad_v2/) | 斑点降低各向异性扩散 v2 |
| [streamcluster](openmp/streamcluster/) | 流聚类 |

---

## OpenCL 编译

### 编译所有程序

```bash
cd ~/rodinia/opencl
make
```

### 编译单个程序

```bash
cd ~/rodinia/opencl/<程序名>
make
```

**示例**:
```bash
cd ~/rodinia/opencl/bfs
make
```

### 已成功编译的程序 (23个)

OpenCL 版本包含所有 OpenMP 程序的 OpenCL 实现，外加：

| 程序 | 描述 |
|------|------|
| [dwt2d](opencl/dwt2d/) | 2D 离散小波变换 |
| [gaussian](opencl/gaussian/) | 高斯滤波 |
| [hybridsort](opencl/hybridsort/) | 混合排序算法 |

### 注意事项

1. **OpenCL 头文件**: 已集成在项目中 (`opencl/_CL_headers/CL/`)
2. **链接库**: 需要确保 `/usr/lib/aarch64-linux-gnu/libOpenCL.so` 存在
3. **编译标志**: 自动添加 `-I$(OPENCL_DIR)/_CL_headers -lOpenCL`

---

## 运行程序

### 数据文件位置

测试数据位于 `data/` 目录：

```bash
ls data/
```

### 运行示例

#### 1. BFS (广度优先搜索)

**OpenMP 版本**:
```bash
cd ~/rodinia/openmp/bfs

# 使用数据文件运行
./bfs ../../data/bfs/graph1M.txt

# 启用输出到文件
OUTPUT=1 ./bfs ../../data/bfs/graph1M.txt

# 查看结果
cat output.txt
```

**OpenCL 版本**:
```bash
cd ~/rodinia/opencl/bfs
./bfs ../../data/bfs/graph1M.txt
```

#### 2. K-means 聚类

```bash
cd ~/rodinia/openmp/kmeans

# 运行程序
./kmeans -n 5 -d 32 -i ../../data/kmeans/kmeans_cpar

# 或使用运行脚本
./run
```

#### 3. Hotspot (热点计算)

```bash
cd ~/rodinia/openmp/hotspot
./hotspot 512 512 1 100 ../../data/hotspot/temp_512 ../../data/hotspot/power_512 out_temp
```

#### 4. 使用运行脚本

大多数程序都有 `run` 脚本：

```bash
cd ~/rodinia/openmp/<程序名>
./run
```

**示例**:
```bash
cd ~/rodinia/openmp/backprop
./run
```

### 验证结果

部分程序提供 `verify` 脚本：

```bash
cd ~/rodinia/openmp/bfs
./verify
```

### 输出控制

#### OpenMP 程序输出控制

许多 OpenMP 程序通过 `OUTPUT` 环境变量控制输出：

```bash
# 启用详细输出
OUTPUT=1 ./bfs ../../data/bfs/graph1M.txt

# 调试模式
DEBUG=1 make
DEBUG=1 ./bfs ../../data/bfs/graph1M.txt
```

#### OpenCL 程序输出控制

OpenCL 程序通常直接输出结果，无需特殊环境变量。

---

## 常见问题

### 1. 编译错误：`cannot find -lOpenCL`

**原因**: OpenCL 库符号链接缺失

**解决方案**:
```bash
sudo ln -sf /usr/lib/aarch64-linux-gnu/libOpenCL.so.1 \
           /usr/lib/aarch64-linux-gnu/libOpenCL.so
```

### 2. OpenMP 编译警告

OpenMP 编译时可能出现警告，这些通常不影响程序运行：

- `warning: format '%d' expects argument of type 'int'`
- `warning: ignoring return value of 'fscanf'`

这些是代码质量问题，可以忽略。

### 3. ARM 架构兼容性问题

某些程序使用 x86 特定指令（如 `rdtsc`），需要修复：

**pathfinder** 已修复，使用 ARM 性能计数器：
```c
#ifdef __aarch64__
    __asm__ __volatile__("mrs %0, cntvct_el0" : "=r"(val));
#else
    __asm__ __volatile__("rdtsc" : "=a"(lo), "=d"(hi));
#endif
```

### 4. C++17 编译错误

OpenCL 程序可能遇到 `throw(string)` 语法错误：

**已修复**: 所有 `CLHelper.h` 和 `.cpp` 文件已更新
- 移除了 `throw(string)` 异常规范
- 修复了 `std::data` 命名冲突

### 5. 数据文件未找到

**错误信息**: `Error Reading graph file`

**解决方案**:
```bash
# 解压数据文件（如果需要）
cd data/bfs
xz -dk graph1M.txt.xz

# 或使用完整路径运行
./bfs /home/orangepi/rodinia/data/bfs/graph1M.txt
```

### 6. OpenCL 设备未找到

**错误信息**: `No OpenCL devices found`

**检查 OpenCL 设备**:
```bash
# 安装 clinfo
sudo apt install clinfo

# 列出 OpenCL 设备
clinfo
```

**可能原因**:
- Mali GPU 驱动未安装
- OpenCL ICD 加载器配置问题

---

## 性能测试

### 使用 time 命令

```bash
time ./bfs ../../data/bfs/graph1M.txt
```

输出示例:
```
real    0m5.234s
user    0m4.987s
sys     0m0.123s
```

### 对比 OpenMP vs OpenCL

```bash
# OpenMP 版本
cd ~/rodinia/openmp/bfs
time ./bfs ../../data/bfs/graph1M.txt

# OpenCL 版本
cd ~/rodinia/opencl/bfs
time ./bfs ../../data/bfs/graph1M.txt
```

---

## 目录结构

```
rodinia/
├── openmp/              # OpenMP 实现
│   ├── bfs/            # 广度优先搜索
│   ├── kmeans/         # K-means 聚类
│   └── ...
├── opencl/              # OpenCL 实现
│   ├── _CL_headers/    # OpenCL 头文件（已集成）
│   ├── bfs/            # 广度优先搜索
│   └── ...
├── data/                # 测试数据
│   ├── bfs/            # BFS 测试图
│   ├── kmeans/         # K-means 数据
│   └── ...
└── common/              # 公共代码
    ├── avi/            # AVI 视频处理库
    └── meschach/       # 矩阵运算库
```

---

## 提示与技巧

### 1. 并行编译

使用 `make -j` 加速编译：

```bash
make -j$(nproc)
```

### 2. 只编译需要的程序

避免编译所有程序以节省时间：

```bash
cd ~/rodinia/openmp/bfs
make
```

### 3. 查看编译命令

```bash
make VERBOSE=1
```

### 4. 自定义编译选项

创建 `Make.user` 文件：

```bash
# ~/rodinia/openmp/Make.user
CFLAGS += -march=native
CXXFLAGS += -march=native
```

---

## CUDA 编译与前置条件

以下内容说明在 ARM64 平台上编译和运行 `cuda` 目录下基准（如 `bfs`、`kmeans` 等）所需的前置条件与常用构建命令。

前置条件：
- 已安装 CUDA Toolkit（包含 `nvcc`），并确认 `nvcc --version` 可用。
- 系统开发工具与头文件：`build-essential`、`libc6-dev`（通常已安装）。
- 若出现缺失 GL 相关头文件，请安装：`libglew-dev`、`freeglut3-dev`。
- 确保 CUDA 库路径存在，例如 `/usr/local/cuda-<VER>/lib64`。

示例（以 CUDA 11.4 安装路径为例）：

```bash
# 设置 CUDA_ROOT 与 nvcc 路径（根据系统实际安装位置调整）
export CUDA_ROOT=/usr/local/cuda-11.4
export PATH="$CUDA_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_ROOT/lib64:$LD_LIBRARY_PATH"

# 安装常见依赖（按需）：
sudo apt update
sudo apt install -y build-essential libc6-dev libglew-dev freeglut3-dev
```

构建 `cuda` 下所有基准：

```bash
cd ~/rodinia/cuda
# 指定 CUDA_ROOT、NVCC 与链接路径以避免系统默认路径问题
make CUDA_ROOT=/usr/local/cuda-11.4 NVCC=/usr/local/cuda-11.4/bin/nvcc \
         LDFLAGS='-L/usr/local/cuda-11.4/lib64' -j$(nproc)
```

单个基准构建示例（以 `bfs` 为例）：

```bash
cd ~/rodinia/cuda/bfs
make CUDA_ROOT=/usr/local/cuda-11.4 NVCC=/usr/local/cuda-11.4/bin/nvcc
```

运行与数据文件：
- 大多数 `cuda` 基准通过 `run` 脚本或可执行文件接收一个输入文件路径（参见 `cuda/bfs/run`）。
- 例如 `bfs` 期望数据文件格式为：
    1) `no_of_nodes`（整数）
    2) 对每个节点：`start` `no_of_edges`（整数对）
    3) `source`（起始节点索引）
    4) `edge_list_size`（整数）
    5) 接着 `edge_list_size` 对整数：`id cost`（程序只使用 `id`）

运行示例：

```bash
# 解压数据（若为 .xz）
xz -dk data/bfs/graph1M.txt.xz

cd ~/rodinia/cuda/bfs
./run            # 脚本会调用 ./bfs ../../data/bfs/graph1M.txt
# 或直接： ./bfs ../../data/bfs/graph1M.txt
```

常见故障与修复：
- 报错 `Error Reading graph file`：检查输入文件路径与格式，或先解压数据文件。
- 报错找不到 `nvcc`：指定 `NVCC` 或把 CUDA bin 加入 `PATH`。
- 链接错误 `cannot find -lcudart`：确保 LDFLAGS 包含 CUDA 库目录（`-L$CUDA_ROOT/lib64`）。

将上述步骤加入文档后即能在 ARM64 平台上编译并运行 `cuda` 目录下的基准。


## 参考资源

- [Rodinia 官方主页](http://lava.cs.virginia.edu/wiki/rodinia)
- [OpenMP 官方文档](https://www.openmp.org/)
- [OpenCL 官方文档](https://www.khronos.org/opencl/)
- [Mali GPU 开发指南](https://developer.arm.com/Tools%20and%20Software/Graphics%20and%20GPU)

---

## 版本信息

- **Rodinia 版本**: 3.1
- **最后更新**: 2026-02-04
- **测试平台**: Orange Pi 5 Plus (Rockchip RK3588, ARM64)
- **编译器**: GCC 11.4.0
- **OpenMP 版本**: 4.5
- **OpenCL 版本**: 1.2 / 3.0 (Mali)
