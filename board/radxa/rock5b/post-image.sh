haos#!/bin/bash

# Rock5B镜像后处理脚本
# 用于生成最终的可烧录系统镜像

set -e  # 遇到错误立即退出

# 初始化路径变量
SCRIPT_DIR="$(dirname "$0")"  # 脚本所在目录
BOARD_DIR="$(dirname "$SCRIPT_DIR")"  # 板级配置目录
BOARD_NAME="$(basename "$BOARD_DIR")"  # 板级名称
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"  # 镜像生成配置文件路径
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"  # 临时目录路径

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    exit 1

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查必要文件
check_files() {
    local missing_files=0  # 记录缺失文件数量
    
    # 检查内核镜像文件是否存在
    if [ ! -f "${BINARIES_DIR}/Image" ]; then
        error "未找到内核镜像文件"
        missing_files=1
    fi

    # 检查设备树文件是否存在
    if [ ! -f "${BINARIES_DIR}/rk3588-rock-5b.dtb" ]; then
        error "未找到设备树文件"
        missing_files=1
    fi

    # 检查U-Boot相关文件
    if [ ! -f "${BINARIES_DIR}/idbloader.img" ]; then
        error "未找到U-Boot SPL文件"
        missing_files=1
    fi

    if [ ! -f "${BINARIES_DIR}/u-boot.itb" ]; then
        error "未找到U-Boot ITB文件"
        missing_files=1
    fi

    # 如果有文件缺失则报错退出
    if [ $missing_files -ne 0 ]; then
        error "缺少生成镜像所需的文件"
    fi
}

# 准备启动配置
prepare_boot() {
    log "正在准备启动配置..."
    
    # 创建extlinux引导目录
    mkdir -p "${BINARIES_DIR}/extlinux"
    
    # 生成extlinux引导配置文件
    cat > "${BINARIES_DIR}/extlinux/extlinux.conf" << EOF
menu title Home Assistant OS Boot Menu
timeout 10
default Home Assistant OS A

label Home Assistant OS A
    kernel /Image
    fdt /rk3588-rock-5b.dtb
    append root=/dev/mmcblk1p4 rootfstype=erofs rootwait console=tty1 console=ttyS2,1500000n8 quiet loglevel=0 systemd.show_status=0

label Home Assistant OS B
    kernel /Image
    fdt /rk3588-rock-5b.dtb
    append root=/dev/mmcblk1p6 rootfstype=erofs rootwait console=tty1 console=ttyS2,1500000n8 quiet loglevel=0 systemd.show_status=0
EOF

    # 创建设备树覆盖层目录
    mkdir -p "${BINARIES_DIR}/overlays"
    
    # 复制README说明文件到覆盖层目录
    cp "${BOARD_DIR}/overlays/README" "${BINARIES_DIR}/overlays/" 2>/dev/null || :
}

# 初始化数据分区
init_data_partition() {
    log "Initializing data partition..."
    
    # 创建临时挂载点
    local mnt_point="${GENIMAGE_TMP}/data_mnt"
    mkdir -p "${mnt_point}"
    
    # 格式化数据分区为ext4 (使用eMMC优化参数)
    mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0 -L "hassos-data" "${BINARIES_DIR}/haos-rock5b.img.p8" 1G
    
    # 挂载并创建基本目录结构
    mount "${BINARIES_DIR}/haos-rock5b.img.p8" "${mnt_point}"
    mkdir -p "${mnt_point}/homeassistant"
    mkdir -p "${mnt_point}/ssl"
    mkdir -p "${mnt_point}/share"
    # 创建扩容标记文件
    touch "${mnt_point}/.haos-expand-needed"
    umount "${mnt_point}"
    rmdir "${mnt_point}"
}

# 初始化misc分区
init_misc_partition() {
    log "Initializing misc partition..."
    
    # 清空misc分区
    dd if=/dev/zero of="${BINARIES_DIR}/haos-rock5b.img.p8" bs=1M count=32
}

# 生成镜像
generate_image() {
    log "Generating system image..."
    
    # 删除旧的临时目录
    rm -rf "${GENIMAGE_TMP}"
    
    # 生成镜像
    genimage \
        --rootpath "${TARGET_DIR}" \
        --tmppath "${GENIMAGE_TMP}" \
        --inputpath "${BINARIES_DIR}" \
        --outputpath "${BINARIES_DIR}" \
        --config "${GENIMAGE_CFG}"
        
    if [ $? -ne 0 ]; then
        error "Image generation failed"
    fi
    
    # 初始化数据分区
    init_data_partition
    
    # 初始化misc分区
    init_misc_partition
}

# 压缩镜像
compress_image() {
    log "Compressing system image..."
    
    if command -v xz >/dev/null 2>&1; then
        xz -T0 -v "${BINARIES_DIR}/haos-rock5b.img"
    else
        warn "xz not found, skipping compression"
    fi
}

# 生成校验和
generate_checksums() {
    log "Generating checksums..."
    
    cd "${BINARIES_DIR}"
    sha256sum haos-rock5b.img.xz > haos-rock5b.img.xz.sha256
}

# 主函数
main() {
    log "Starting post-image processing for Rock5B..."
    
    # 检查必要文件
    check_files
    
    # 准备启动配置
    prepare_boot
    
    # 生成镜像
    generate_image
    
    # 压缩镜像
    compress_image
    
    # 生成校验和
    generate_checksums
    
    log "Post-image processing completed successfully"
}

# 执行主函数
main "$@"