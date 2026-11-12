#!/usr/bin/env bash
# ==============================================================================
# SteamOS Kit for Omarchy / Arch Linux (Hyprland Wayland Compositor)
# Automated Installation Script
# ==============================================================================

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_BIN="${HOME}/.local/bin"

echo "🎮 Installing SteamOS Kit for Omarchy..."

# 1. Create target directories
mkdir -p "$CONFIG_DIR/omarchy/plugins/steamos-desktop"
mkdir -p "$CONFIG_DIR/omarchy/plugins/steamos-workspaces"
mkdir -p "$CONFIG_DIR/omarchy/themes/steamos"
mkdir -p "$CONFIG_DIR/omarchy/branding"
mkdir -p "$CONFIG_DIR/omarchy/extensions"
mkdir -p "$CONFIG_DIR/environment.d"
mkdir -p "$STATE_DIR/omarchy/workspace-layouts"
mkdir -p "$LOCAL_BIN"

# 2. Copy SteamOS Desktop & Workspaces Plugins
echo "📦 Installing steamos-desktop and steamos-workspaces plugins..."
cp -r "$KIT_DIR/config/omarchy/plugins/steamos-desktop/"* "$CONFIG_DIR/omarchy/plugins/steamos-desktop/"
cp -r "$KIT_DIR/config/omarchy/plugins/steamos-workspaces/"* "$CONFIG_DIR/omarchy/plugins/steamos-workspaces/"

# 3. Copy SteamOS Theme & Plymouth Assets
echo "🎨 Installing steamos theme and unlock screen..."
cp -r "$KIT_DIR/config/omarchy/themes/steamos/"* "$CONFIG_DIR/omarchy/themes/steamos/"

# 4. Copy Branding (About logo)
echo "🏷️  Installing Valve Steam About branding..."
cp "$KIT_DIR/config/omarchy/branding/about.txt" "$CONFIG_DIR/omarchy/branding/about.txt"

# 5. Copy Menu Extension
echo "📋 Installing Super+Space SteamOS menu entries..."
cp "$KIT_DIR/config/omarchy/extensions/omarchy-menu.jsonc" "$CONFIG_DIR/omarchy/extensions/omarchy-menu.jsonc"

# 6. Copy and make helper scripts executable
echo "⚙️  Installing helper binaries..."
cp "$KIT_DIR/local/bin/steamos-menu-action" "$LOCAL_BIN/steamos-menu-action"
chmod +x "$LOCAL_BIN/steamos-menu-action"
if [[ -f "$KIT_DIR/local/bin/omarchy-hyprland-workspace-layout-current" ]]; then
  cp "$KIT_DIR/local/bin/omarchy-hyprland-workspace-layout-current" "$LOCAL_BIN/omarchy-hyprland-workspace-layout-current"
  chmod +x "$LOCAL_BIN/omarchy-hyprland-workspace-layout-current"
fi

# 7. Configure floating layout for Workspace 1 and stable collation for shell dock
echo "🖥️  Configuring Workspace 1 floating mode for SteamOS dock..."
echo 'o.workspace_mode({ workspace = "1", mode = "floating" })' > "$STATE_DIR/omarchy/workspace-layouts/1.lua"
echo "LC_COLLATE=C" > "$CONFIG_DIR/environment.d/locale.conf"

# 8. Copy Hyprland configuration (Workspace 1 floating mode, SteamOS shortcuts & autostart)
echo "🪄 Installing Hyprland configuration..."
mkdir -p "$CONFIG_DIR/hypr"
cp "$KIT_DIR/config/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
cp "$KIT_DIR/config/hypr/bindings.lua" "$CONFIG_DIR/hypr/bindings.lua"
cp "$KIT_DIR/config/hypr/autostart.lua" "$CONFIG_DIR/hypr/autostart.lua"
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

# 9. Enable plugins, configure bar workspaces, apply theme, and reload Omarchy shell
if command -v omarchy >/dev/null 2>&1; then
  echo "🔄 Enabling SteamOS plugins and applying theme..."
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  omarchy plugin enable steamos.desktop >/dev/null 2>&1 || true
  omarchy plugin disable omarchy.workspaces >/dev/null 2>&1 || true
  omarchy plugin enable steamos.workspaces --section left --after omarchy.menu >/dev/null 2>&1 || true
  omarchy theme set steamos >/dev/null 2>&1 || true
  omarchy-shell -q omarchy.workspaces refresh >/dev/null 2>&1 || true
  omarchy-shell -q steamos.workspaces refresh >/dev/null 2>&1 || true
  omarchy-shell -q omarchy.dock refresh >/dev/null 2>&1 || true
  omarchy restart shell >/dev/null 2>&1 || true
fi

echo "✅ SteamOS Kit installation completed successfully!"
echo "👉 Switch to Workspace 1 (SteamOS) via SUPER+é to enjoy your gaming environment!"
