#!/bin/bash

# Manual Snapshot Setup Commands
# Run these commands manually with sudo when ready
# Usage: bash ~/.dotfiles/scripts/system/setup-snapshots-manual.sh

echo "🕰️ MANUAL SNAPSHOT SETUP COMMANDS"
echo "=================================="
echo ""
echo "Copy and paste these commands one by one:"
echo ""

echo "# 1. Configure Snapper for root filesystem:"
echo "sudo snapper -c root create-config /"
echo ""

echo "# 2. Enable snapper systemd timers:"
echo "sudo systemctl enable --now snapper-timeline.timer"
echo "sudo systemctl enable --now snapper-cleanup.timer"
echo ""

echo "# 3. Create initial snapper snapshot:"
echo "sudo snapper -c root create --description 'Initial system setup'"
echo ""

echo "# 4. Configure Timeshift for BTRFS:"
cat << 'EOF'
sudo tee /etc/timeshift/timeshift.json > /dev/null << 'EOT'
{
  "backup_device_uuid" : "",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5"
}
EOT
EOF

echo ""
echo "# 5. Create initial timeshift snapshot:"
echo "sudo timeshift --create --comments 'Initial BTRFS setup' --tags D"
echo ""

echo "# 6. Add timeshift cron jobs:"
cat << 'EOF'
(sudo crontab -l 2>/dev/null; cat << 'EOT'
# Daily timeshift snapshot at 1 AM
0 1 * * * /usr/bin/timeshift --create --scripted --comments "Daily automatic backup" --tags D >> /var/log/timeshift-cron.log 2>&1
EOT
) | sudo crontab -
EOF

echo ""
echo "# 7. Check status:"
echo "sudo timeshift --list"
echo "sudo snapper -c root list"
echo "systemctl status snapper-timeline.timer"
echo ""

echo "🎯 QUICK TEST COMMANDS:"
echo "======================"
echo ""
echo "# Test current snapshots:"
echo "sudo btrfs subvolume list /"
echo ""
echo "# Check timers:"
echo "systemctl list-timers | grep snapper"
echo ""
echo "# Check cron:"
echo "sudo crontab -l | grep timeshift"
echo ""

echo "💡 TIP: Run these commands step by step and check each one works before continuing!"