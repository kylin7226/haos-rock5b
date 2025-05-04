#!/bin/bash

# Rock5B专用系统钩子脚本
# 用于Home Assistant OS的初始化配置

set -e  # 遇到错误立即退出

# 硬件相关常量定义
ROCK5B_HWID="ROCK 5B"  # Rock5B硬件标识
REQUIRED_DISK_SIZE=16G  # 最小磁盘空间要求(16GB)

# 检查硬件是否为Rock5B开发板
check_hardware() {
    # 从设备树中读取硬件型号并验证
    if ! grep -q "$ROCK5B_HWID" /proc/device-tree/model; then
        echo "ERROR: Hardware is not Rock5B"  # 保持错误信息为英文
        exit 1
    fi
}

# 扩展data分区使用剩余空间
expand_data_partition() {
    local disk="$1"
    local data_part="${disk}p8"
    
    # 安装必要工具
    if ! command -v growpart &> /dev/null; then
        apt-get update && apt-get install -y cloud-guest-utils
    fi

    # 扩展分区
    growpart "$disk" 8 || {
        echo "ERROR: Failed to expand data partition"
        return 1
    }

    # 扩展文件系统
    resize2fs "$data_part" || {
        echo "ERROR: Failed to resize data filesystem"
        return 1
    }
}

# 检查存储设备是否符合要求
check_storage() {
    local disk="$1"  # 传入参数：磁盘设备路径
    
    # 检查是否为块设备
    if [ ! -b "$disk" ]; then
        echo "ERROR: $disk is not a block device"  # 保持错误信息为英文
        exit 1
    fi

    # 获取磁盘大小并检查是否满足最低要求
    local size=$(blockdev --getsize64 "$disk")
    if [ "$size" -lt $(numfmt --from=iec "$REQUIRED_DISK_SIZE") ]; then
        echo "ERROR: Disk too small (min $REQUIRED_DISK_SIZE required)"
        exit 1
    fi

    # 检查分区表是否包含所有必需分区
    if ! blkid -t TYPE=erofs -o device | grep -q "${disk}p4"; then
        echo "ERROR: Missing rootfs_a partition"
        exit 1
    fi
    if ! blkid -t TYPE=erofs -o device | grep -q "${disk}p6"; then
        echo "ERROR: Missing rootfs_b partition"
        exit 1
    fi
    if ! blkid -t TYPE="8DA63339-0007-60C0-C436-083AC8230908" -o device | grep -q "${disk}p7"; then
        echo "ERROR: Missing misc partition"
        exit 1
    fi
    if ! blkid -t TYPE=ext4 -o device | grep -q "${disk}p8"; then
        echo "ERROR: Missing data partition"
        exit 1
    fi

    # 首次启动时扩展data分区
    if [ ! -f /var/lib/haos/.data_partition_expanded ]; then
        expand_data_partition "$disk" && \
        touch /var/lib/haos/.data_partition_expanded
    fi
}

# 编译设备树覆盖层
compile_overlays() {
    echo "Compiling device tree overlays..."  # 保持输出为英文
    
    # 创建覆盖层目录
    local overlay_dir="/boot/overlays"
    mkdir -p "$overlay_dir"

    # 编译/boot/overlays-src目录下所有.dts文件
    for dts in /boot/overlays-src/*.dts; do
        # 生成.dtbo输出文件名
        dtbo="${dts%.dts}.dtbo"
        
        # 使用dtc编译器将.dts转换为.dtbo
        dtc -I dts -O dtb -o "$overlay_dir/$(basename $dtbo)" "$dts" || {
            echo "Failed to compile $dts"  # 保持错误信息为英文
            return 1
        }
    done
}

# 设置RAUC更新系统
setup_rauc() {
    # 安装RAUC配置文件
    install -D -m 644 /boot/rauc.conf /etc/rauc/rauc.conf

    # 设置密钥环(此处为示例密钥)
    mkdir -p /etc/rauc
    if [ ! -f /etc/rauc/keyring.pem ]; then
        # 生成2048位RSA密钥
        openssl genrsa -out /etc/rauc/keyring.pem 2048
    fi

    # 启用RAUC服务
    systemctl enable rauc.service
}

# 设置SSH服务
setup_ssh() {
    # 创建SSH配置目录
    mkdir -p /etc/ssh

    # 配置SSH端口和root登录(带安全设置)
    cat > /etc/ssh/sshd_config.d/custom.conf << EOF
Port 56222
PermitRootLogin yes
PasswordAuthentication yes
MaxAuthTries 3
LoginGraceTime 60
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitEmptyPasswords no
EOF

    # 设置配置文件权限(仅root可读写)
    chmod 600 /etc/ssh/sshd_config.d/custom.conf

    # 设置root密码(将被哈希存储)
    echo 'root:Passw0rd' | chpasswd

    # 强制首次登录时修改密码
    chage -d 0 root

    # 启用SSH服务
    systemctl enable ssh.service
}

# 设置所有系统服务
setup_services() {
    # 设置中国时区
    timedatectl set-timezone "Asia/Shanghai"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    echo "Asia/Shanghai" > /etc/timezone

    # eMMC优化配置
    echo "mq-deadline" > /sys/block/mmcblk1/queue/scheduler
    echo 128 > /sys/block/mmcblk1/queue/nr_requests
    echo 1 > /sys/block/mmcblk1/queue/add_random
    echo 0 > /sys/block/mmcblk1/queue/rotational
    echo 0 > /sys/block/mmcblk1/queue/iostats

    # 更新fstab中的data分区挂载选项
    sed -i '/\/mnt\/data/s/defaults/noatime,nodiratime,discard,commit=60,data=writeback/' /etc/fstab

    # 启用风扇控制服务
    systemctl enable rock5b-fan.service

    # 设置SSH服务
    setup_ssh

    # 加载NPU驱动
    echo "rknpu" > /etc/modules-load.d/rknpu.conf

    # 优化显示输出(减少轮询)
    echo "options drm_kms_helper poll=0" > /etc/modprobe.d/drm.conf

    # 编译设备树覆盖层
    compile_overlays

    # 设置RAUC更新系统
    setup_rauc

    # 设置OTA更新服务
    install -m 755 /boot/haos-ota-update /usr/local/bin/
    systemctl enable haos-ota.service

    # 创建版本文件
    echo "Rock5B-$(date +%Y%m%d)" > /etc/haos-release
}

# 主程序流程 - 根据参数执行不同阶段
case "$1" in
    pre-install)
        # 预安装阶段: 检查硬件和存储
        echo "Running Rock5B pre-install hooks..."  # 保持输出为英文
        check_hardware
        check_storage "$2"  # $2为存储设备参数
        ;;
    post-install)
        # 安装后阶段: 设置所有服务
        echo "Running Rock5B post-install hooks..."
        setup_services

        # 应用性能优化
        echo "vm.swappiness=10" >> /etc/sysctl.conf  # 减少交换内存使用
        ;;
    *)
        # 参数错误处理
        echo "Usage: $0 {pre-install|post-install} [device]"
        exit 1
        ;;
esac

exit 0  # 正常退出