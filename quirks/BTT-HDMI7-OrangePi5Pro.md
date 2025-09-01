# BigTreeTech 7" HDMI Touch Display – Orange Pi 5 Pro Setup

This display needs a **custom CVT modeline** because its EDID timings don’t sync properly, and also it seems that Orange Pi 5 Pro shows the connection as DP rather than HDMI!
 
Two parts make it reliable:

---

## 1. Xorg configuration (boot-time)

File: `/etc/X11/xorg.conf.d/60-btt.conf`

```ini
Section "Monitor"
  Identifier "DP-1"
  Modeline "1024x600_60.00" 49.50  1024 1072 1176 1328  600 603 613 624 -hsync +vsync
  Option "PreferredMode" "1024x600_60.00"
EndSection

Section "Device"
  Identifier "Device0"
  Driver "modesetting"
EndSection

Section "Screen"
  Identifier "Screen0"
  Device "Device0"
  Monitor "DP-1"
  DefaultDepth 24
  SubSection "Display"
    Depth 24
    Modes "1024x600_60.00"
  EndSubSection
EndSection
```

👉 Ensures the panel boots into the **49.5 MHz CVT mode** every time.

---

## 2. Hot-plug recovery (when HDMI cable is unplugged/replugged)

- Script: `/usr/local/bin/hotplug-btt.sh`  
- Rule: `/etc/udev/rules.d/99-btt-hotplug.rules`

**`/usr/local/bin/hotplug-btt.sh`**

```bash
#!/bin/bash
USER=pi
export DISPLAY=:0
export XAUTHORITY=/home/$USER/.Xauthority
MODE="1024x600_60.00"
MODELINE="49.50 1024 1072 1176 1328 600 603 613 624 -hsync +vsync"

log() { logger -t hotplug-btt "$1"; }

log "Starting hotplug mode setup"

if ! sudo -u "$USER" xrandr | grep -q "$MODE"; then
  log "Defining new mode $MODE"
  sudo -u "$USER" xrandr --newmode "$MODE" $MODELINE
  sudo -u "$USER" xrandr --addmode DP-1 "$MODE"
fi

sudo -u "$USER" xrandr --output DP-1 --off
sleep 1
sudo -u "$USER" xrandr --output DP-1 --mode "$MODE"
log "Mode reapplied"
```

**`/etc/udev/rules.d/99-btt-hotplug.rules`**

```udev
ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", RUN+="/usr/local/bin/hotplug-btt.sh"
```

👉 Ensures the mode is reapplied whenever DP-1 reconnects.  

Check logs with:

```bash
journalctl -t hotplug-btt -f
```

---

## Reinstall checklist

1. Install system normally.  
2. Copy these three files back:  
   - `/etc/X11/xorg.conf.d/60-btt.conf`  
   - `/usr/local/bin/hotplug-btt.sh` (chmod +x)  
   - `/etc/udev/rules.d/99-btt-hotplug.rules`  
3. Reboot.  

✅ That’s all — the display will work on boot **and** after hotplug events.

