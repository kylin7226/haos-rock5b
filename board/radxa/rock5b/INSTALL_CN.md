# HAOS Rock5B 安装指南

## 硬件要求
- Radxa Rock5B 开发板
- 至少16GB的microSD卡或eMMC模块
- 5V/4A电源适配器
- 网络连接(有线或无线)

## 安装步骤

### 1. 下载镜像
从[发布页面](https://github.com/kylin7226/haos-rock5b/releases)下载最新的HAOS镜像文件(.img.xz)。

### 2. 烧录镜像
```bash
# 解压镜像
unxz haos-rock5b-*.img.xz

# 烧录到存储设备(请替换sdX为您的设备)
sudo dd if=haos-rock5b-*.img of=/dev/sdX bs=4M status=progress
sync
```

### 3. 首次启动
1. 将存储设备插入Rock5B
2. 连接电源启动设备
3. 等待系统初始化完成(约3-5分钟)
4. 系统会自动扩展数据分区到全部可用空间

**扩容说明**：
- 扩容过程可能需要额外1-2分钟
- 可通过LED指示灯状态判断进度
- 完成后会自动重启一次

**验证扩容**：
```bash
df -h /mnt/data
```

### 4. SSH远程访问
系统默认开启SSH服务，配置如下：
- 端口: 56222
- 用户名: root
- 默认密码: Passw0rd
- 首次登录将强制要求修改密码

SSH连接示例：
```bash
ssh root@<设备IP> -p 56222
```

⚠️ 安全提示：
- 首次登录后必须修改默认密码
- 建议使用SSH密钥进行身份验证
- 定期更改密码以提高安全性
- 避免在不安全的网络环境下使用SSH

### 5. 访问Home Assistant
在浏览器中访问：`http://rock5b-ip:8123`

## 更新方法

### OTA在线更新
系统会自动检查并提示可用更新，或手动执行：
```bash
sudo haos-ota-update
```

### 手动更新
1. 下载.raucb更新包
2. 执行：
```bash
sudo rauc install update.raucb
```

## 系统配置指南

### 性能调优
```bash
# CPU性能模式
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# GPU性能模式
echo performance > /sys/class/misc/mali0/device/devfreq/ff9a0000.gpu/governor

# I/O调度器
echo mq-deadline > /sys/block/mmcblk1/queue/scheduler

# 内存优化
echo 10 > /proc/sys/vm/swappiness
echo 50 > /proc/sys/vm/vfs_cache_pressure
```

### 系统监控
```bash
# 查看系统状态
cat /var/log/system-monitor.log

# 实时监控工具
htop    # CPU/内存监控
iotop   # 磁盘I/O监控
nmon    # 综合性能监控
```

### 设备树覆盖
```bash
# 添加自定义设备树
1. 创建.dts文件到/boot/overlays-src/
2. 系统会自动编译为.dtbo
3. 在/boot/config.txt中添加overlay=your-overlay

# 常用覆盖:
- uart4: 启用额外串口
- i2c4: 添加I2C总线
- spi3: 启用SPI接口
```

### 网络优化
```bash
# 有线网络配置
nmtui  # 图形配置工具

# 无线网络连接
nmcli device wifi list
nmcli device wifi connect <SSID> password <密码>

# 网络性能优化
ethtool -K eth0 rx off tx off  # 禁用校验和卸载
```

### 硬件支持
```bash
# NPU测试
rknn_test --device rockchip

# GPU信息
glxinfo | grep OpenGL

# PCIe设备列表
lspci -vv
```

## 常见问题

### Q: 首次启动无显示？
A: 确保使用HDMI 2.0及以上规格的线缆

### Q: 网络连接失败？
A: 检查`/boot/network-config`文件配置

### Q: SSH连接被拒绝？
A: 检查以下几点：
1. 确认使用正确的端口号(56222)
2. 确认设备IP地址正确
3. 确认网络连接正常
4. 检查防火墙设置

### Q: 如何启用调试模式？
A: 在/boot目录下创建`debug`空文件

## 更多帮助
访问项目[GitHub仓库](https://github.com/kylin7226/haos-rock5b)获取支持