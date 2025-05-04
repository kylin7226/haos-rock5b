# HAOS Rock5B 本地开发环境要求

## 1. 系统要求

### 1.1 操作系统
- **推荐**: Ubuntu 22.04 LTS 或更新版本
- **支持**: 任何支持容器引擎(Docker)的Linux发行版
- **最低要求**:
  - 内核版本: 5.10+
  - glibc: 2.35+

### 1.2 硬件要求
- CPU: 4核以上 (推荐8核)
- 内存: 8GB以上 (推荐16GB)
- 磁盘空间: 50GB可用空间 (构建过程需要约15GB临时空间)

## 2. 必需依赖项

### 2.1 基础工具
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y \
    build-essential \
    git \
    make \
    gcc \
    g++ \
    bison \
    flex \
    libssl-dev \
    libncurses-dev \
    bc \
    python3 \
    python3-pip \
    device-tree-compiler \
    dosfstools \
    e2fsprogs \
    parted \
    udev \
    curl \
    wget \
    xz-utils \
    file
```

### 2.2 构建工具
```bash
# Buildroot 依赖
sudo apt install -y \
    rsync \
    cpio \
    unzip \
    gcc-multilib \
    g++-multilib \
    lib32stdc++6 \
    lib32z1

# 镜像生成工具
sudo apt install -y \
    genimage \
    mtools \
    gptfdisk \
    e2tools
```

### 2.3 可选工具
```bash
# 开发调试工具
sudo apt install -y \
    qemu-user-static \
    binfmt-support \
    gdb \
    strace \
    ltrace \
    patchelf

# 性能监控
sudo apt install -y \
    htop \
    iotop \
    nmon
```

## 3. 版本要求

### 3.1 关键工具版本
| 工具 | 最低版本 | 推荐版本 | 验证命令 |
|------|----------|----------|----------|
| 构建工具(make) | 4.2 | 4.3 | `make --version` |
| 编译器(gcc) | 9.0 | 11.3 | `gcc --version` |
| 版本控制(git) | 2.25 | 2.34 | `git --version` |
| Python解释器 | 3.8 | 3.10 | `python3 --version` |
| 容器引擎(Docker) | 20.10 | 23.0 | `docker --version` |

### 3.2 内核头文件
```bash
# 检查内核头文件
sudo apt install -y linux-headers-$(uname -r)
ls /usr/src/linux-headers-$(uname -r)
```

## 4. 环境验证

### 4.1 快速检查脚本
```bash
#!/bin/bash
# 保存为check-env.sh并运行

check_tool() {
    if command -v $1 >/dev/null; then
        echo -e "\e[32m[OK]\e[0m $1: $(command -v $1)"
    else
        echo -e "\e[31m[MISSING]\e[0m $1"
    fi
}

echo "=== 开发环境检查 ==="
check_tool make
check_tool gcc
check_tool git
check_tool docker
check_tool dtc
check_tool genimage
```

### 4.2 详细验证
```bash
# 运行完整环境检查
./board/radxa/rock5b/verify-build.sh --check-only

# 检查输出中的[PASS]标记
```

## 5. 故障排除

### 5.1 常见问题
1. **缺少头文件**:
   ```bash
   sudo apt install linux-headers-$(uname -r)
   ```

2. **权限问题**:
   ```bash
   # 将用户加入docker组
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **磁盘空间不足**:
   ```bash
   # 清理旧构建
   make clean
   # 或指定大容量目录
   BUILD_DIR=/path/to/large/disk ./verify-build.sh
   ```

4. **网络问题**:
   ```bash
   # 使用国内镜像源
   export BUILDROOT_DL_DIR="https://mirrors.tuna.tsinghua.edu.cn/buildroot"
   ```

## 6. 高级配置

### 6.1 使用Podman替代Docker
```bash
sudo apt install -y podman
alias docker=podman
```

### 6.2 离线构建
```bash
# 预下载所有源码
make source
# 离线构建
make BUILD_OFFLINE=1
```

### 6.3 交叉编译
```bash
# 安装交叉编译工具链
sudo apt install -y gcc-aarch64-linux-gnu
export CROSS_COMPILE=aarch64-linux-gnu-
```

## 7. 参考链接
- [Buildroot手册](https://buildroot.org/downloads/manual/manual.html)
- [Rock5B文档](https://wiki.radxa.com/Rock5/5b)
- [Docker安装指南](https://docs.docker.com/engine/install/ubuntu/)