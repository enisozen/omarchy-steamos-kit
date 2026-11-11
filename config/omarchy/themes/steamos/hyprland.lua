-- SteamOS Deck Edition - Hyprland Theme
local active_border_color = { colors = { "rgba(1a9fffee)", "rgba(66c0f4ee)", "rgba(a855f7dd)" }, angle = 45 }
local inactive_border_color = "rgba(1b2838cc)"
local active_shadow_color = "rgba(1a9fff55)"
local inactive_shadow_color = "rgba(05070a66)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    rounding = 10,
    active_opacity = 0.96,
    inactive_opacity = 0.90,
    shadow = {
      enabled = true,
      range = 22,
      render_power = 3,
      color = active_shadow_color,
      color_inactive = inactive_shadow_color,
    },
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      new_optimizations = true,
      xray = false,
      noise = 0.015,
      contrast = 1.10,
      brightness = 0.98,
      vibrancy = 0.45,
      vibrancy_darkness = 0.20,
      popups = true,
      special = true,
    },
  },
})

hl.layer_rule({
  match = { namespace = "^(omarchy-bar|omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-clipboard|omarchy-emojis|omarchy-image-selector|omarchy-keyboard-panel|omarchy-network-qr)$" },
  blur = true,
  ignore_alpha = 0.2,
})

o.transparent_window({ tag = "terminal" }, "0.93 0.87")
o.transparent_window("(omawrite|1[pP]assword|com\\.onepassword\\.OnePassword|org\\.gnome\\.Nautilus)", "0.93 0.87")
o.transparent_window({ tag = "transparent" }, "0.93 0.87")
o.window("^(steamos-deck|steam|steam_app_.*|gamescope)$", { opacity = "1.0 1.0" })
