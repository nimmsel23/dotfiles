#!/bin/bash

# 🧠 Nur einmal ausführen
pgrep -f hypr-autostart-lock >/dev/null && exit
touch /tmp/hypr-autostart-lock

# 📡 NetworkManager Applet (nur wenn nicht GNOME)
pgrep nm-applet >/dev/null || nm-applet &

# 🔐 Polkit Agent (GNOME-Version, auch für Wayland)
pgrep polkit-gnome-authentication-agent-1 >/dev/null || \
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# 🖼 XDG Desktop Portal (für Flatpak, Screenshare etc.)
# Nur einmal starten, falls nicht systemd-gespawnt
pgrep xdg-desktop-portal-hyprland >/dev/null || \
/usr/lib/xdg-desktop-portal-hyprland &

# 🕹 Starte Waybar (optional)
pgrep waybar >/dev/null || waybar &

# 🌗 Mondphasen-Skript (optional)
~/.config/waybar/scripts/moon.sh &

# 🧭 Telegram Hub (wenn vorhanden)
pgrep -f telegram_hub.py >/dev/null || \
python ~/.local/bin/telegram_hub.py &

# 🐟 Starte terminal mit Fish (z. B. foot, kitty, alacritty)
# alacritty &

# ✅ Debug-Ausgabe
notify-send "Hyprland autostart executed"
