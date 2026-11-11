-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Launch Steam on boot after background initializes.
o.exec_on_start("sh -c 'for i in $(seq 1 60); do alpha=$(hyprctl layers -j 2>/dev/null | jq -r \".. | select(.namespace? == \\\"omarchy-background\\\") | .alpha\" 2>/dev/null | head -n 1); if [[ \"$alpha\" == \"1\" ]]; then break; fi; sleep 0.25; done; sleep 0.5; (pgrep -x steam >/dev/null 2>&1 || setsid /usr/bin/steam >/dev/null 2>&1 &)'")
