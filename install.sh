#!/usr/bin/env bash
# ==============================================================================
# SteamOS Kit for Omarchy / Arch Linux (Hyprland Wayland Compositor)
# Automated Installation Script
# ==============================================================================

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="${HOME}/.local/bin"

echo "🎮 Installing SteamOS Kit for Omarchy..."

# 1. Create target directories
mkdir -p "$CONFIG_DIR/omarchy/plugins/steamos-desktop"
mkdir -p "$CONFIG_DIR/omarchy/themes/steamos"
mkdir -p "$CONFIG_DIR/omarchy/branding"
mkdir -p "$CONFIG_DIR/omarchy/extensions"
mkdir -p "$LOCAL_BIN"

# 2. Copy SteamOS Plugin
echo "📦 Installing steamos-desktop plugin..."
cp -r "$KIT_DIR/config/omarchy/plugins/steamos-desktop/"* "$CONFIG_DIR/omarchy/plugins/steamos-desktop/"

# 3. Copy SteamOS Theme & Plymouth Assets
echo "🎨 Installing steamos theme and unlock screen..."
cp -r "$KIT_DIR/config/omarchy/themes/steamos/"* "$CONFIG_DIR/omarchy/themes/steamos/"

# 4. Copy Branding (About logo)
echo "🏷️  Installing Valve Steam About branding..."
cp "$KIT_DIR/config/omarchy/branding/about.txt" "$CONFIG_DIR/omarchy/branding/about.txt"

# 5. Copy Menu Extension
echo "📋 Installing Super+Space SteamOS menu entries..."
cp "$KIT_DIR/config/omarchy/extensions/omarchy-menu.jsonc" "$CONFIG_DIR/omarchy/extensions/omarchy-menu.jsonc"

# 6. Copy and make steamos-menu-action executable
echo "⚙️  Installing steamos-menu-action helper..."
cp "$KIT_DIR/local/bin/steamos-menu-action" "$LOCAL_BIN/steamos-menu-action"
chmod +x "$LOCAL_BIN/steamos-menu-action"

# 7. Hyprland configuration recommendations
echo "🪄 Checking Hyprland configuration..."
if [[ -f "$CONFIG_DIR/hypr/bindings.lua" ]]; then
  if ! grep -q "steamos-menu-action" "$CONFIG_DIR/hypr/bindings.lua"; then
    echo "💡 Note: Ensure your ~/.config/hypr/bindings.lua includes SteamOS shortcuts."
  fi
fi

# 8. Reload menus and plugins
if command -v omarchy >/dev/null 2>&1; then
  echo "🔄 Reloading Omarchy shell and menus..."
  omarchy menu refresh >/dev/null 2>&1 || true
  omarchy plugin reload steamos-desktop >/dev/null 2>&1 || true
fi

echo "✅ SteamOS Kit installation completed successfully!"
echo "👉 Switch to Workspace 1 to enjoy your new SteamOS desktop environment!"
