#!/bin/bash

# File: /usr/local/bin/network-recovery-check.sh
# Make executable: chmod +x /usr/local/bin/network-recovery-check.sh

MOONRAKER_API="http://127.0.0.1:7125/printer/gcode/script"

# Find the first connected interface with an IP (non-loopback)
IFACE=$(ip -br addr | awk '$2 == "UP" && $1 != "lo" { print $1; exit }')

# If no interface found, exit early
if [ -z "$IFACE" ]; then
  echo "No active network interface found."
  curl -s -X POST -H "Content-Type: application/json" \
       -d '{"script":"M117 No network interface!"}' \
       "$MOONRAKER_API"
  exit 1
fi

# Get the IP address of that interface
IP=$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1)

# Check if IP is assigned
if [ -z "$IP" ]; then
  echo "No IP address detected on $IFACE. Restarting network stack..."
  curl -s -X POST -H "Content-Type: application/json" \
       -d "{\"script\":\"M117 No IP on $IFACE! Restarting network...\"}" \
       "$MOONRAKER_API"

  # Optional: delay for 5 seconds to allow NetworkManager time to recover
  sleep 5

  # Restart networking components
  sudo systemctl restart NetworkManager.service
  sudo systemctl restart wpa_supplicant.service
  sudo systemctl restart systemd-networkd.service || true

  # Avoid repeat execution in the same boot
  touch /run/network_recovery_done
else
  echo "Network is healthy on $IFACE with IP: $IP"
  curl -s -X POST -H "Content-Type: application/json" \
       -d "{\"script\":\"M117 Network healthy on $IFACE: $IP\"}" \
       "$MOONRAKER_API"
fi
