#!/bin/bash

# 获取系统信息用于RAUC更新
get_system_info() {
    # 获取当前启动分区
    BOOT_SLOT=$(cat /proc/cmdline | grep -o 'rauc.slot=\w' | cut -d= -f2)
    
    # 获取系统版本
    SYSTEM_VERSION=$(cat /etc/haos-release)
    
    # 获取硬件信息
    BOARD_MODEL=$(cat /proc/device-tree/model)
    
    # 获取存储信息
    STORAGE_INFO=$(df -h / | tail -n1)
    
    # 获取内存信息
    MEMORY_INFO=$(free -h | grep Mem)
    
    # 获取CPU温度
    CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    CPU_TEMP_C=$((CPU_TEMP/1000))
    
    # 输出JSON格式的系统信息
    cat << EOF
{
    "boot_slot": "${BOOT_SLOT}",
    "system_version": "${SYSTEM_VERSION}",
    "board_model": "${BOARD_MODEL}",
    "storage": {
        "root": "${STORAGE_INFO}"
    },
    "memory": "${MEMORY_INFO}",
    "temperature": {
        "cpu": ${CPU_TEMP_C}
    },
    "compatible": "haos-rock5b",
    "update_status": {
        "last_update": "$(date -r /var/lib/rauc/status.json 2>/dev/null || echo 'never')",
        "boot_count": "$(fw_printenv -n BOOT_COUNT 2>/dev/null || echo '0')"
    }
}
EOF
}

# 执行系统信息收集
get_system_info