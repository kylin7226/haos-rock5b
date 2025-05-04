# Rock5B Installation Guide

## 1. Preparation
- Radxa Rock5B board
- Minimum 16GB storage device
- Power supply
- Network connection

## 2. Installation Steps
1. Download the latest HAOS image
2. Write image to storage device using tools like balenaEtcher
3. Safely eject the storage device

## 3. First Boot
1. Insert the storage device into Rock5B
2. Connect power to start the device
3. Wait for system initialization (approx. 3-5 minutes)
4. Automatic storage expansion will occur (additional 1-2 minutes)

**About Expansion**:
- The system will automatically expand data partition
- LED indicators show progress
- One automatic reboot will occur after completion

**Verify Expansion**:
```bash
df -h /mnt/data
```

## 4. Post-Installation
- Connect via web interface at `http://homeassistant.local:8123`
- Follow on-screen setup instructions

## Troubleshooting
- If boot fails, verify the image writing process
- Check power supply stability
- Consult community forums for support