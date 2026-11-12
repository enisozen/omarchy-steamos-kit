-- Ensure ~/.local/bin takes precedence and collation is stable for scripts
local home = os.getenv("HOME") or ""
hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or ""))
hl.env("LC_COLLATE", "C")

-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- ==================== STEAMOS DESKTOP & GAMING WORKSPACE 1 ====================
-- Keep Workspace 1 persistent so it never gets destroyed when empty
hl.workspace_rule({ workspace = "1", persistent = true })

-- Set Workspace 1 as a native floating desktop environment (with dock, floating windows & titlebars)
o.workspace_mode({ workspace = "1", mode = "floating" })

-- Big Picture Mode and Gamescope go fullscreen on Workspace 1.
o.window({ class = "^steam$", title = "^(Steam Big Picture.*|Steam Geniş Ekran.*)$" }, {
  workspace = "1",
  fullscreen = true,
  border_size = 0,
  rounding = 0,
})

-- Automatically enforce fullscreen when Big Picture launches
local function is_bpm_title(t)
  if not t then return false end
  return t:match("^Steam Big Picture") ~= nil or t:match("^Steam Geniş Ekran") ~= nil
end

hl.on("window.open", function(window)
  if not window then return end
  local c = window.class or ""
  local t = window.title or ""
  if c == "steam" and is_bpm_title(t) then
    hl.timer(function()
      hl.dispatch(hl.dsp.window.fullscreen({
        mode = "fullscreen",
        action = "set",
        window = "address:" .. window.address,
      }))
    end, { type = "oneshot", timeout = 10 })
  end
end)

hl.on("window.title", function(window)
  if window and window.class == "steam" and is_bpm_title(window.title or "") then
    hl.timer(function()
      hl.dispatch(hl.dsp.window.fullscreen({
        mode = "fullscreen",
        action = "set",
        window = "address:" .. window.address,
      }))
    end, { type = "oneshot", timeout = 10 })
  end
end)
