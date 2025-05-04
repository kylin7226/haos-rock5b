# HAOS Rock5B 用户指南

## 1. 系统安装

### 1.1 硬件要求
- Radxa Rock5B开发板
- 至少16GB的microSD卡或eMMC模块
- 5V/4A电源适配器
- 网络连接(有线或无线)

### 1.2 下载镜像
从[发布页面](https://github.com/kylin7226/haos-rock5b/releases)下载最新的HAOS镜像文件(.img.xz)。

### 1.3 烧录镜像
```bash
# 解压镜像
unxz haos-rock5b-*.img.xz

# 烧录到存储设备(请替换sdX为您的设备)
sudo dd if=haos-rock5b-*.img of=/dev/sdX bs=4M status=progress
sync
```

### 1.4 首次启动
1. 将存储设备插入Rock5B
2. 连接电源启动设备
3. 等待系统初始化完成(约3-5分钟)

## 2. 系统配置

### 2.1 存储管理
#### 动态扩容功能
系统首次启动时会自动将数据分区扩展到整个存储设备的剩余空间。

**验证扩容状态**：
```bash
# 查看分区使用情况
df -h /mnt/data

# 检查扩容标记
cat /var/lib/haos/.data_partition_expanded
```

**手动扩容(如需)**：
```bash
# 扩展分区表
growpart /dev/mmcblk1 8

# 扩展文件系统
resize2fs /dev/mmcblk1p8
```

**优化建议**：
- 使用`noatime`挂载选项减少写入
- 定期执行`fstrim`维护SSD性能

### 2.2 网络配置
```bash
# 有线网络(自动获取IP)
nmcli device connect eth0

# 无线网络
nmcli device wifi list
nmcli device wifi connect <SSID> password <密码>
```

### 2.2 SSH访问
```bash
# 连接示例
ssh root@<设备IP> -p 56222

# 首次登录信息
- 用户名: root
- 默认密码: Passw0rd (首次登录需修改)
```

### 2.3 系统更新
```bash
# 手动检查更新
haos-ota-check

# 手动执行更新
haos-ota-update
```

## 3. 硬件支持

### 3.1 状态监控
```bash
# 查看中央处理器(CPU)温度
cat /sys/class/thermal/thermal_zone0/temp

# 查看图形处理器(GPU)状态
cat /sys/class/misc/mali0/device/devfreq/ff9a0000.gpu/cur_freq

# 查看神经网络处理器(NPU)状态
rknn_test --device rockchip
```

### 3.2 性能调优
```bash
# 中央处理器(CPU)性能模式
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 图形处理器(GPU)性能模式
echo performance > /sys/class/misc/mali0/device/devfreq/ff9a0000.gpu/governor

# 内存优化
echo 10 > /proc/sys/vm/swappiness
```

## 4. 常见问题

### 4.1 首次启动无显示
- 确保使用HDMI 2.0及以上规格的线缆
- 检查电源适配器是否达标

### 4.2 网络连接失败
- 检查`/boot/network-config`文件配置
- 验证网络接口状态`ip a`

### 4.3 系统恢复
1. 按住恢复按钮上电
2. 通过USB连接电脑
3. 使用rkflash工具重刷系统

## 5. 开发者指南

### 5.1 本地构建验证
```bash
# 克隆仓库
git clone https://github.com/kylin7226/haos-rock5b
cd haos-rock5b

# 运行构建验证脚本
./board/radxa/rock5b/verify-build.sh

# 输出镜像位置
ls -lh build/output/images/
```

### 5.2 设备树覆盖
```bash
# 添加自定义设备树
1. 创建.dts文件到/boot/overlays-src/
2. 系统会自动编译为.dtbo
3. 在/boot/config.txt中添加overlay=your-overlay
```

### 5.2 调试模式
```bash
# 启用调试日志
touch /boot/debug
reboot
```

## 6. 获取帮助
- [官方文档](https://wiki.radxa.com/Rock5/5b)
- [GitHub Issues](https://github.com/kylin7226/haos-rock5b/issues)
- 社区论坛: forum.radxa.com