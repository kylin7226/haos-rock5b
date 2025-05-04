# HAOS Rock5B User Guide

## 1. System Installation

### 1.1 Hardware Requirements
- Radxa Rock5B board
- At least 16GB microSD card or eMMC module
- 5V/4A power adapter
- Network connection (wired or wireless)

### 1.2 Download Image
Download the latest HAOS image (.img.xz) from [Releases](https://github.com/kylin7226/haos-rock5b/releases).

### 1.3 Flash Image
```bash
# Decompress image
unxz haos-rock5b-*.img.xz

# Flash to storage device (replace sdX)
sudo dd if=haos-rock5b-*.img of=/dev/sdX bs=4M status=progress
sync
```

### 1.4 First Boot
1. Insert storage device into Rock5B
2. Power on the device
3. Wait for system initialization (~3-5 minutes)

## 2. System Configuration

### 2.1 Storage Management
#### Automatic Expansion
The system will automatically expand the data partition to utilize all available storage space during first boot.

**Verify expansion status**:
```bash
# Check partition usage
df -h /mnt/data

# Check expansion flag
cat /var/lib/haos/.data_partition_expanded
```

**Manual expansion (if needed)**:
```bash
# Expand partition table
growpart /dev/mmcblk1 8

# Resize filesystem
resize2fs /dev/mmcblk1p8
```

**Optimization tips**:
- Use `noatime` mount option to reduce writes
- Regularly run `fstrim` for SSD maintenance

### 2.2 Network Setup
```bash
# Wired network (DHCP)
nmcli device connect eth0

# Wireless network
nmcli device wifi list
nmcli device wifi connect <SSID> password <password>
```

### 2.2 SSH Access
```bash
# Connection example
ssh root@<device-ip> -p 56222

# First login:
- Username: root
- Default password: Passw0rd (must change at first login)
```

### 2.3 System Update
```bash
# Check for updates
haos-ota-check

# Perform update
haos-ota-update
```

## 3. Hardware Support

### 3.1 Status Monitoring
```bash
# Check CPU temperature
cat /sys/class/thermal/thermal_zone0/temp

# Check GPU status
cat /sys/class/misc/mali0/device/devfreq/ff9a0000.gpu/cur_freq

# Check NPU status
rknn_test --device rockchip
```

### 3.2 Performance Tuning
```bash
# CPU performance mode
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# GPU performance mode
echo performance > /sys/class/misc/mali0/device/devfreq/ff9a0000.gpu/governor

# Memory optimization
echo 10 > /proc/sys/vm/swappiness
```

## 4. Troubleshooting

### 4.1 No Display on First Boot
- Use HDMI 2.0+ cable
- Check power adapter rating

### 4.2 Network Issues
- Check `/boot/network-config`
- Verify interface status: `ip a`

### 4.3 System Recovery
1. Hold recovery button while powering on
2. Connect via USB
3. Reflash using rkflash tool

## 5. Advanced Features

### 5.1 Device Tree Overlays
```bash
# Add custom overlay:
1. Create .dts file in /boot/overlays-src/
2. System will auto-compile to .dtbo
3. Add overlay=your-overlay to /boot/config.txt
```

### 5.2 Debug Mode
```bash
# Enable debug logs
touch /boot/debug
reboot
```

## 6. Getting Help
- [Official Docs](https://wiki.radxa.com/Rock5/5b)
- [GitHub Issues](https://github.com/kylin7226/haos-rock5b/issues)
- Community Forum: forum.radxa.com