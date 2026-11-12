#!/usr/bin/env bash
# ==============================================================================
# Omarchy / Arch Linux İçin SteamOS Masaüstü & Konsol Kiti
# Otomatik Kurulum Betiği (Türkçe)
# ==============================================================================

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
LOCAL_BIN="${HOME}/.local/bin"

echo "🎮 Omarchy SteamOS Kiti Kuruluyor..."

# 1. Hedef dizinleri oluştur
mkdir -p "$CONFIG_DIR/omarchy/plugins/steamos-desktop"
mkdir -p "$CONFIG_DIR/omarchy/plugins/steamos-menu"
mkdir -p "$CONFIG_DIR/omarchy/themes/steamos"
mkdir -p "$CONFIG_DIR/omarchy/branding"
mkdir -p "$CONFIG_DIR/omarchy/extensions"
mkdir -p "$CONFIG_DIR/environment.d"
mkdir -p "$STATE_DIR/omarchy/workspace-layouts"
mkdir -p "$LOCAL_BIN"

# 2. SteamOS Masaüstü & Menü Eklentilerini Kopyala
echo "📦 SteamOS masaüstü ve menü eklentileri yükleniyor..."
cp -r "$KIT_DIR/config/omarchy/plugins/steamos-desktop/"* "$CONFIG_DIR/omarchy/plugins/steamos-desktop/"
cp -r "$KIT_DIR/config/omarchy/plugins/steamos-menu/"* "$CONFIG_DIR/omarchy/plugins/steamos-menu/"

# 3. SteamOS Teması & Başlangıç Kilit Görselleri
echo "🎨 SteamOS teması ve kilit açma ekranı yükleniyor..."
cp -r "$KIT_DIR/config/omarchy/themes/steamos/"* "$CONFIG_DIR/omarchy/themes/steamos/"

# 4. Hakkında Logosu
echo "🏷️  Valve Steam ASCII logosu yerleştiriliyor..."
cp "$KIT_DIR/config/omarchy/branding/about.txt" "$CONFIG_DIR/omarchy/branding/about.txt"

# 5. Menü Genişletmesi
echo "📋 Süper + Boşluk SteamOS menü kısayolları yükleniyor..."
cp "$KIT_DIR/config/omarchy/extensions/omarchy-menu.jsonc" "$CONFIG_DIR/omarchy/extensions/omarchy-menu.jsonc"

# 6. Yardımcı ikili dosyaları kur ve yetkilendir
echo "⚙️  Yardımcı betikler kuruluyor..."
cp "$KIT_DIR/local/bin/steamos-menu-action" "$LOCAL_BIN/steamos-menu-action"
chmod +x "$LOCAL_BIN/steamos-menu-action"
if [[ -f "$KIT_DIR/local/bin/omarchy-hyprland-workspace-layout-current" ]]; then
  cp "$KIT_DIR/local/bin/omarchy-hyprland-workspace-layout-current" "$LOCAL_BIN/omarchy-hyprland-workspace-layout-current"
  chmod +x "$LOCAL_BIN/omarchy-hyprland-workspace-layout-current"
fi

# 7. Çalışma Alanı 1'i dock için yüzer (floating) moda ayarla ve dil sıralamasını sabitle
echo "🖥️  Çalışma Alanı 1 dock için yüzer (floating) moda ayarlanıyor..."
echo 'o.workspace_mode({ workspace = "1", mode = "floating" })' > "$STATE_DIR/omarchy/workspace-layouts/1.lua"
echo "LC_COLLATE=C" > "$CONFIG_DIR/environment.d/locale.conf"

# 8. Hyprland yapılandırmasını kur (Çalışma Alanı 1, SteamOS kısayolları ve otomatik başlatma)
echo "🪄 Hyprland yapılandırması yükleniyor..."
mkdir -p "$CONFIG_DIR/hypr"
cp "$KIT_DIR/config/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
cp "$KIT_DIR/config/hypr/bindings.lua" "$CONFIG_DIR/hypr/bindings.lua"
cp "$KIT_DIR/config/hypr/autostart.lua" "$CONFIG_DIR/hypr/autostart.lua"
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

# 9. SteamOS eklentilerini etkinleştir, üst barı yapılandır, temayı uygula ve Omarchy kabuğunu yenile
if command -v omarchy >/dev/null 2>&1; then
  echo "🔄 SteamOS eklentileri ve teması etkinleştiriliyor..."
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  omarchy plugin enable steamos.desktop >/dev/null 2>&1 || true
  omarchy plugin enable steamos.menu --section left --index 0 >/dev/null 2>&1 || true
  omarchy plugin disable omarchy.menu >/dev/null 2>&1 || true
  omarchy theme set steamos >/dev/null 2>&1 || true
  omarchy-shell -q omarchy.workspaces refresh >/dev/null 2>&1 || true
  omarchy-shell -q omarchy.dock refresh >/dev/null 2>&1 || true
  omarchy restart shell >/dev/null 2>&1 || true
fi

echo "✅ SteamOS Kiti kurulumu başarıyla tamamlandı!"
echo "👉 Çalışma Alanı 1'e geçerek SteamOS ortamını kullanmaya başlayabilirsiniz!"
