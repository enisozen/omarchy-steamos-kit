-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

-- Replace SUPER+G (was: Toggle window grouping) with Google Chrome, and move Toggle window grouping to SUPER+U.
o.rebind("SUPER + G", "Google Chrome", { launch = "google-chrome-stable" })
o.bind("SUPER + U", "Toggle window grouping", hl.dsp.group.toggle())

-- Launch Digiturk beIN CONNECT with SUPER+B (SUPER+B was previously unassigned).
o.bind("SUPER + B", "beIN CONNECT (Digiturk)", { webapp = "https://www.beinconnect.com.tr" })

-- Launch Netflix with SUPER+N (SUPER+N was previously unassigned).
o.bind("SUPER + N", "Netflix", { webapp = "https://www.netflix.com" })

-- Replace SUPER+A (was: Select all) with Apple TV, and move Select all to SUPER+E.
o.rebind("SUPER + A", "Apple TV", { webapp = "https://tv.apple.com" })
o.bind("SUPER + E", "Select all", function()
  hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "A", state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "A", state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end)

-- Replace SUPER+P (was: Pseudo window) with Amazon Prime Video, and move Pseudo window to SUPER+D.
o.rebind("SUPER + P", "Amazon Prime Video", { webapp = "https://www.primevideo.com" })
o.bind("SUPER + D", "Pseudo window", hl.dsp.window.pseudo())

-- Replace SUPER+SHIFT+M (was: Music / Spotify) with Apple Music.
o.rebind("SUPER + SHIFT + M", "Apple Music", { webapp = "https://music.apple.com" })

-- Replace SUPER+SHIFT+S (was: Google Maps) with SteamOS Console / Big Picture toggle.
o.rebind("SUPER + SHIFT + S", "SteamOS Konsol / Geniş Ekran Geçişi", function()
  hl.dispatch(o.workspaces.focus(1))
  local active = hl.get_active_window()
  if active and active.class == "steam" and (active.fullscreen or 0) > 0 then
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset", window = "address:" .. active.address }))
  else
    os.execute("steamos-menu-action bigpicture &")
  end
end)

-- SteamOS Console is dedicated to Workspace 1.
-- Numeric keys 1..9 map to Desktops 1..9 (Hyprland Workspaces 2..10), so moving a window to 1..9 never touches SteamOS.
for i = 1, 9 do
  local key = "code:" .. tostring(i + 9)
  local target_ws = i + 1
  o.rebind("SUPER + " .. key, "Masaüstü " .. i .. "'e geç", o.workspaces.focus(target_ws))
  o.rebind("SUPER + SHIFT + " .. key, "Pencereyi Masaüstü " .. i .. "'e taşı", o.workspaces.move_window(target_ws))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Pencereyi sessizce Masaüstü " .. i .. "'e taşı", o.workspaces.move_window(target_ws, false))
end

-- Switch to SteamOS via SUPER+0 or SUPER+code:49 (key left of 1).
o.rebind("SUPER + code:19", "SteamOS'a geç", o.workspaces.focus(1))
o.bind("SUPER + code:49", "SteamOS'a geç", o.workspaces.focus(1))

-- Prevent moving applications to SteamOS via keybindings.
local function block_move_to_steamos()
  os.execute("notify-send -u low -a 'SteamOS' 'SteamOS Konsol Koruması' 'SteamOS konsol ekranına başka uygulama taşınamaz.' &")
end
o.rebind("SUPER + SHIFT + code:19", "SteamOS koruması", block_move_to_steamos)
o.rebind("SUPER + SHIFT + ALT + code:19", "SteamOS koruması", block_move_to_steamos)
o.bind("SUPER + SHIFT + code:49", "SteamOS koruması", block_move_to_steamos)
o.bind("SUPER + SHIFT + ALT + code:49", "SteamOS koruması", block_move_to_steamos)

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
