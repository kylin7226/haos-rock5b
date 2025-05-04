# HAOS Rock5B Development Environment Requirements

## 1. System Requirements

### 1.1 Operating System
- **Recommended**: Ubuntu 22.04 LTS or newer
- **Supported**: Any Linux distro with Docker support
- **Minimum**:
  - Kernel: 5.10+
  - glibc: 2.35+

### 1.2 Hardware
- CPU: 4+ cores (8 recommended)
- RAM: 8GB+ (16GB recommended)
- Storage: 50GB+ free space (~15GB temp space needed)

## 2. Required Dependencies

### 2.1 Base Tools
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

### 2.2 Build Tools
```bash
# Buildroot dependencies
sudo apt install -y \
    rsync \
    cpio \
    unzip \
    gcc-multilib \
    g++-multilib \
    lib32stdc++6 \
    lib32z1

# Image generation
sudo apt install -y \
    genimage \
    mtools \
    gptfdisk \
    e2tools
```

### 2.3 Optional Tools
```bash
# Debugging
sudo apt install -y \
    qemu-user-static \
    binfmt-support \
    gdb \
    strace \
    ltrace \
    patchelf

# Monitoring
sudo apt install -y \
    htop \
    iotop \
    nmon
```

## 3. Version Requirements

### 3.1 Key Tools
| Tool | Min Version | Recommended | Check Command |
|------|-------------|-------------|---------------|
| make | 4.2 | 4.3 | `make --version` |
| gcc | 9.0 | 11.3 | `gcc --version` |
| git | 2.25 | 2.34 | `git --version` |
| python | 3.8 | 3.10 | `python3 --version` |
| docker | 20.10 | 23.0 | `docker --version` |

### 3.2 Kernel Headers
```bash
# Install headers
sudo apt install -y linux-headers-$(uname -r)
ls /usr/src/linux-headers-$(uname -r)
```

## 4. Environment Verification

### 4.1 Quick Check Script
```bash
#!/bin/bash
# Save as check-env.sh

check_tool() {
    if command -v $1 >/dev/null; then
        echo -e "\e[32m[OK]\e[0m $1: $(command -v $1)"
    else
        echo -e "\e[31m[MISSING]\e[0m $1"
    fi
}

echo "=== Dev Environment Check ==="
check_tool make
check_tool gcc
check_tool git
check_tool docker
check_tool dtc
check_tool genimage
```

### 4.2 Full Verification
```bash
# Run complete check
./board/radxa/rock5b/verify-build.sh --check-only
```

## 5. Troubleshooting

### 5.1 Common Issues
1. **Missing Headers**:
   ```bash
   sudo apt install linux-headers-$(uname -r)
   ```

2. **Permission Issues**:
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **Low Disk Space**:
   ```bash
   # Clean previous builds
   make clean
   # Or specify large storage
   BUILD_DIR=/path/to/large/disk ./verify-build.sh
   ```

4. **Network Problems**:
   ```bash
   # Use mirror in China
   export BUILDROOT_DL_DIR="https://mirrors.tuna.tsinghua.edu.cn/buildroot"
   ```

## 6. Advanced Configuration

### 6.1 Podman Alternative
```bash
sudo apt install -y podman
alias docker=podman
```

### 6.2 Offline Build
```bash
# Pre-download sources
make source
# Build offline
make BUILD_OFFLINE=1
```

### 6.3 Cross-Compilation
```bash
# Install cross-compiler
sudo apt install -y gcc-aarch64-linux-gnu
export CROSS_COMPILE=aarch64-linux-gnu-
```

## 7. References
- [Buildroot Manual](https://buildroot.org/downloads/manual/manual.html)
- [Rock5B Docs](https://wiki.radxa.com/Rock5/5b)
- [Docker Install](https://docs.docker.com/engine/install/ubuntu/)