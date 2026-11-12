-- Extra autostart processes.
-- Auto-mount storage drives (such as Depo) if available
o.exec_on_start("sh -c 'udisksctl mount -b /dev/disk/by-label/Depo 2>/dev/null || udisksctl mount -b /dev/sda2 2>/dev/null || true'")

-- Launch Steam in Big Picture (GamepadUI) mode on boot after background initializes.
o.exec_on_start("sh -c 'for i in $(seq 1 60); do alpha=$(hyprctl layers -j 2>/dev/null | jq -r \".. | select(.namespace? == \\\"omarchy-background\\\") | .alpha\" 2>/dev/null | head -n 1); if [[ \"$alpha\" == \"1\" ]]; then break; fi; sleep 0.25; done; sleep 0.5; if pgrep -x steam >/dev/null 2>&1; then setsid /usr/bin/steam steam://open/bigpicture >/dev/null 2>&1 & else setsid /usr/bin/steam -gamepadui >/dev/null 2>&1 & fi'")
