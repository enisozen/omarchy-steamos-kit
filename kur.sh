#!/usr/bin/env bash
# ==============================================================================
# Omarchy / Arch Linux İçin SteamOS Masaüstü & Konsol Kiti
# Otomatik Kurulum Betiği (Türkçe)
# ==============================================================================

set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="${HOME}/.local/bin"

echo "🎮 Omarchy SteamOS Kiti Kuruluyor..."

# 1. Hedef dizinleri oluştur
mkdir -p "$CONFIG_DIR/omarchy/plugins/steamos-desktop"
mkdir -p "$CONFIG_DIR/omarchy/themes/steamos"
mkdir -p "$CONFIG_DIR/omarchy/branding"
mkdir -p "$CONFIG_DIR/omarchy/extensions"
mkdir -p "$LOCAL_BIN"

# 2. SteamOS Masaüstü Eklentisini Kopyala
echo "📦 SteamOS masaüstü eklentisi yükleniyor..."
cp -r "$KIT_DIR/config/omarchy/plugins/steamos-desktop/"* "$CONFIG_DIR/omarchy/plugins/steamos-desktop/"

# 3. SteamOS Teması & Başlangıç Kilit Görselleri
echo "🎨 SteamOS teması ve kilit açma ekranı yükleniyor..."
cp -r "$KIT_DIR/config/omarchy/themes/steamos/"* "$CONFIG_DIR/omarchy/themes/steamos/"

# 4. Hakkında Logosu
echo "🏷️  Valve Steam ASCII logosu yerleştiriliyor..."
cp "$KIT_DIR/config/omarchy/branding/about.txt" "$CONFIG_DIR/omarchy/branding/about.txt"

# 5. Menü Genişletmesi
echo "📋 Süper + Boşluk SteamOS menü kısayolları yükleniyor..."
cp "$KIT_DIR/config/omarchy/extensions/omarchy-menu.jsonc" "$CONFIG_DIR/omarchy/extensions/omarchy-menu.jsonc"

# 6. steamos-menu-action eylemini kur ve yetkilendir
echo "⚙️  SteamOS eylem yöneticisi kuruluyor..."
cp "$KIT_DIR/local/bin/steamos-menu-action" "$LOCAL_BIN/steamos-menu-action"
chmod +x "$LOCAL_BIN/steamos-menu-action"

# 7. Hyprland yapılandırması kontrolü & otomatik başlatma
echo "🪄 Hyprland yapılandırması kontrol ediliyor..."
if [[ -f "$CONFIG_DIR/hypr/autostart.lua" ]]; then
  if grep -q "setsid /usr/bin/steam >/dev/null" "$CONFIG_DIR/hypr/autostart.lua"; then
    echo "⚡ autostart.lua dosyasındaki Steam otomatik başlatması Geniş Ekran (GamepadUI) moduna güncelleniyor..."
    sed -i 's|setsid /usr/bin/steam >/dev/null.*|if pgrep -x steam >/dev/null 2>\&1; then setsid /usr/bin/steam steam://open/bigpicture >/dev/null 2>\&1 \& else setsid /usr/bin/steam -gamepadui >/dev/null 2>\&1 \& fi'\''")|g' "$CONFIG_DIR/hypr/autostart.lua"
  fi
fi
if [[ -f "$CONFIG_DIR/hypr/bindings.lua" ]]; then
  if ! grep -q "steamos-menu-action" "$CONFIG_DIR/hypr/bindings.lua"; then
    echo "💡 Not: ~/.config/hypr/bindings.lua dosyanızda SteamOS kısayollarının bulunduğundan emin olun."
  fi
fi

# 8. Omarchy Menü ve Eklentileri Yenile
if command -v omarchy >/dev/null 2>&1; then
  echo "🔄 Omarchy kabuğu ve menüler güncelleniyor..."
  omarchy menu refresh >/dev/null 2>&1 || true
  omarchy plugin reload steamos-desktop >/dev/null 2>&1 || true
fi

echo "✅ SteamOS Kiti kurulumu başarıyla tamamlandı!"
echo "👉 Çalışma Alanı 1'e geçerek SteamOS ortamını kullanmaya başlayabilirsiniz!"
