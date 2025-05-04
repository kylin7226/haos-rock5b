#!/bin/bash
# HAOS Rock5B 本地编译验证脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BUILD_DIR="${BUILD_DIR:-$(pwd)/build}"
OUTPUT_DIR="${BUILD_DIR}/output/images"
TEMP_DIR="${BUILD_DIR}/tmp"

# 日志函数
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查函数
check_file() {
    if [ -f "$1" ]; then
        log "Found $1"
    else
        error "Missing file: $1"
    fi
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        log "Command $1 available"
    else
        error "Missing command: $1"
    fi
}

# 准备构建环境
prepare_build() {
    # 创建构建目录和临时目录
    log "正在准备构建环境..."
    mkdir -p "${BUILD_DIR}" "${TEMP_DIR}"
    
    # 检查磁盘空间是否足够(至少需要15GB)
    local free_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 15728640 ]; then
        warn "磁盘空间不足 (可用: ${free_space}KB, 推荐: 15GB)"
    fi
}

# 执行构建过程
run_build() {
    log "正在执行构建过程..."
    
    # 如果不存在配置文件，则生成默认配置
    if [ ! -f "${BUILD_DIR}/.config" ]; then
        make O="${BUILD_DIR}" rock5b_defconfig
    fi
    
    # 使用多核并行编译
    make O="${BUILD_DIR}" -j$(nproc)
    
    # 检查构建是否成功
    if [ $? -ne 0 ]; then
        error "构建失败"
    fi
}

# 验证生成的镜像文件
verify_image() {
    log "正在验证生成的镜像文件..."
    
    # 检查必要的镜像文件是否存在
    check_file "${OUTPUT_DIR}/haos-rock5b.img"          # 原始镜像文件
    check_file "${OUTPUT_DIR}/haos-rock5b.img.xz"      # 压缩后的镜像
    check_file "${OUTPUT_DIR}/haos-rock5b.img.sha256"   # 校验和文件
    
    # 验证镜像文件的SHA256校验和
    (cd "${OUTPUT_DIR}" && sha256sum -c haos-rock5b.img.sha256) || error "镜像文件校验失败"
}

# 生成测试报告
generate_report() {
    local report_file="${BUILD_DIR}/build-report.txt"
    
    echo "=== HAOS Rock5B Build Report ===" > "$report_file"
    echo "Date: $(date)" >> "$report_file"
    echo "Build Directory: ${BUILD_DIR}" >> "$report_file"
    echo "Output Directory: ${OUTPUT_DIR}" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Generated Images:" >> "$report_file"
    ls -lh "${OUTPUT_DIR}" | grep "haos-rock5b" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "Flash Instructions:" >> "$report_file"
    echo "1. Uncompress image: xz -d haos-rock5b.img.xz" >> "$report_file"
    echo "2. Flash to device: sudo dd if=haos-rock5b.img of=/dev/sdX bs=4M status=progress" >> "$report_file"
    echo "3. Sync: sync" >> "$report_file"
    
    log "Build report generated at ${report_file}"
}

# 主流程
main() {
    echo -e "\n=== Starting HAOS Rock5B Build Verification ==="
    
    # 初始检查
    check_file "configs/rock5b_defconfig"
    check_file "board/radxa/rock5b/rauc.conf"
    check_command "make"
    check_command "gcc"
    
    # 准备环境
    prepare_build
    
    # 执行构建
    run_build
    
    # 验证输出
    verify_image
    
    # 生成报告
    generate_report
    
    echo -e "\n=== Verification Successful ==="
    echo -e "${GREEN}Image ready for testing at: ${OUTPUT_DIR}/haos-rock5b.img.xz${NC}"
    echo -e "Flash instructions saved in build report"
}

main "$@"