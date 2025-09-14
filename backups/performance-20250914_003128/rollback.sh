#!/bin/bash
# Performance Tweaks Rollback Script
# Generated automatically

echo "Rolling back performance tweaks..."

# Stop services
sudo systemctl stop tlp 2>/dev/null
sudo systemctl disable tlp 2>/dev/null
sudo systemctl stop auto-cpufreq 2>/dev/null
sudo systemctl disable auto-cpufreq 2>/dev/null
sudo systemctl stop preload 2>/dev/null
sudo systemctl disable preload 2>/dev/null

# Remove configuration files
sudo rm -f /etc/sysctl.d/99-performance-safe.conf
sudo rm -f /etc/NetworkManager/conf.d/safe-performance.conf
sudo rm -f /etc/udev/rules.d/60-ioschedulers.rules
sudo rm -f /etc/tlp.conf.d/99-safe-performance.conf

# Restore backups if they exist
BACKUP_DIR="$(dirname "$0")"

if [ -f "$BACKUP_DIR/grub.backup" ]; then
    echo "Restoring GRUB configuration..."
    sudo cp "$BACKUP_DIR/grub.backup" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

if [ -f "$BACKUP_DIR/tlp.conf.original" ]; then
    echo "Restoring original TLP configuration..."
    sudo cp "$BACKUP_DIR/tlp.conf.original" /etc/tlp.conf
fi

# Restart services
sudo systemctl restart NetworkManager
sudo sysctl --system

echo "Rollback completed. Please reboot to ensure all changes take effect."
echo "Reboot now? [y/N]"
read -r reboot_confirm
if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
    sudo reboot
fi
