import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
  id: root

  // Command Runner Helper
  function runCmd(cmd) {
    var p = procComponent.createObject(root, { command: ["sh", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"] })
    p.running = true
  }

  Component {
    id: procComponent
    Process {
      onExited: destroy()
    }
  }

  // Live Telemetry & System State
  property int cpuPercent: 8
  property string ramUsedGb: "2.5"
  property int tdpLimit: 15
  property int gpuClock: 1600
  property int fanProfile: 1 // 0: Sessiz, 1: Dengeli, 2: Turbo
  property int fpsLimit: 60
  property int overlayLevel: 1
  property int fsrSharpness: 3

  // Ekran & Ses
  property bool nightLight: false
  property int brightnessLevel: 100
  property int refreshRate: 60 // 40, 60
  property int volumeLevel: 75
  property bool isMuted: false

  // Ağ & BT
  property bool bluetoothOn: true
  property bool wifiConnected: true

  // Steam
  property string protonVer: "Proton Experimental"
  property bool shaderPreCache: true
  property string statusMsg: "SteamOS 3.6 Holo Masaüstü Hazır"

  // Telemetry Poller
  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      telemetryProc.running = true
    }
  }

  Process {
    id: telemetryProc
    command: ["sh", "-c", "cpu=$(grep 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$4+$5; if (NR>0) print int((u*100)/t)}'); mem=$(free -m | awk '/Mem:/ {printf \"%.1f\", $3/1024}'); echo \"$cpu|$mem\""]
    stdout: SplitParser {
      onRead: function(data) {
        var parts = data.trim().split("|")
        if (parts.length >= 2) {
          var c = parseInt(parts[0])
          if (!isNaN(c) && c >= 0 && c <= 100) root.cpuPercent = c
          if (parts[1]) root.ramUsedGb = parts[1]
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData

      screen: modelData
      color: "transparent"

      readonly property var monitor: Hyprland.monitorFor(screen)
      readonly property var workspace: monitor ? monitor.activeWorkspace : null
      readonly property int workspaceId: workspace ? workspace.id : -1

      // Only visible when on Workspace 1 (SteamOS Workspace)
      readonly property bool onWorkspace1: workspaceId === 1
      visible: true

      WlrLayershell.namespace: "omarchy-steamos-desktop"
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }

      // Input mask: Left icons and Right widgets receive input; center and empty desktop pass through
      mask: Region {
        item: window.onWorkspace1 ? leftIconsCol : null
        Region { item: window.onWorkspace1 ? widgetsCol : null }
      }

      property int selectedIcon: -1

      Item {
        anchors.fill: parent
        opacity: window.onWorkspace1 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // ==================== ÖZEL STEAM DUVAR KAĞIDI (SADECE WORKSPACE 1) ====================
        Image {
          id: customWallpaper
          anchors.fill: parent
          source: "file:///home/omarchy/.config/omarchy/plugins/steamos-desktop/steam-wallpaper-4k.png"
          fillMode: Image.PreserveAspectCrop
          cache: true
          z: 0
        }

        // ==================== 1. SİMGELER SOLDA (DESKTOP ICONS ON LEFT) ====================
        Column {
          id: leftIconsCol
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.topMargin: 46
          anchors.leftMargin: 36
          spacing: 20
          z: 10

          // 1. Ev (Home)
          DesktopIcon {
            idx: 0
            glyph: "󰋜"
            iconCol: "#38bdf8"
            label: "Ev"
            sublabel: "Kullanıcı Dosyaları (~/)"
            onLaunched: root.runCmd("nautilus ~")
          }

          // 2. Çöp Kutusu (Trash)
          DesktopIcon {
            idx: 1
            glyph: "󰩹"
            iconCol: "#f43f5e"
            label: "Çöp Kutusu"
            sublabel: "Silinen Dosyalar"
            onLaunched: root.runCmd("nautilus trash:///")
          }

          // 3. Chrome (Google Chrome)
          DesktopIcon {
            idx: 2
            glyph: "󰊯"
            iconCol: "#fbbf24"
            label: "Chrome"
            sublabel: "Google Chrome Web Tarayıcısı"
            onLaunched: root.runCmd("google-chrome-stable")
          }

          // 4. Steam Normal Mod
          DesktopIcon {
            idx: 3
            glyph: "󰓓"
            iconCol: "#66c0f4"
            label: "Steam\nNormal Mod"
            sublabel: "Klasik Steam Masaüstü İstemcisi"
            onLaunched: root.runCmd("steamos-menu-action normal")
          }

          // 5. Steam Geniş Mod (BPM)
          DesktopIcon {
            idx: 4
            glyph: "󰊗"
            iconCol: "#00e5ff"
            badge: "BPM"
            label: "Steam\nGeniş Mod"
            sublabel: "Steam Deck Big Picture Arayüzü"
            onLaunched: root.runCmd("steamos-menu-action bigpicture")
          }
        }

        // ==================== 2. AYRI AYRI MASAÜSTÜ WIDGETLERİ (SAĞDA) ====================
        Column {
          id: widgetsCol
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.topMargin: 44
          anchors.rightMargin: 36
          spacing: 14
          width: 386
          z: 20

          // ----------------------------------------------------
          // WIDGET 1: STEAM DECK PERFORMANS & DONANIM MONİTÖRÜ
          // ----------------------------------------------------
          Rectangle {
            id: perfWidgetCard
            width: parent.width
            height: 294
            radius: 14
            color: "#f0090e17"
            border.color: "#1e344e"
            border.width: 1.5

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              // Header
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                  Layout.preferredWidth: 28
                  Layout.preferredHeight: 28
                  radius: 7
                  color: "#102338"
                  border.color: "#00d2ff"
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "󰓅"
                    color: "#00d2ff"
                    font.pixelSize: 15
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text {
                    textFormat: Text.PlainText
                    text: "PERFORMANS & DONANIM"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.1
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: "Steam Deck Canlı Telemetri"
                    color: "#38bdf8"
                    font.pixelSize: 9
                  }
                }

                // Live Pulse Badge
                Rectangle {
                  Layout.preferredWidth: 46
                  Layout.preferredHeight: 18
                  radius: 4
                  color: "#052e16"
                  border.color: "#22c55e"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Rectangle { width: 5; height: 5; radius: 2.5; color: "#22c55e" }
                    Text { textFormat: Text.PlainText; text: "CANLI"; color: "#4ade80"; font.pixelSize: 8; font.bold: true }
                  }
                }
              }

              // Telemetry Chips (4 chips in a row)
              RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 38
                  radius: 6
                  color: "#121b27"
                  border.color: "#1d2e42"
                  border.width: 1
                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: "CPU"; color: "#64748b"; font.pixelSize: 7; font.bold: true }
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.cpuPercent + "%"; color: "#38bdf8"; font.pixelSize: 11; font.bold: true }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 38
                  radius: 6
                  color: "#121b27"
                  border.color: "#1d2e42"
                  border.width: 1
                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: "RAM"; color: "#64748b"; font.pixelSize: 7; font.bold: true }
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.ramUsedGb + "G"; color: "#c084fc"; font.pixelSize: 11; font.bold: true }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 38
                  radius: 6
                  color: "#121b27"
                  border.color: "#1d2e42"
                  border.width: 1
                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: "GPU"; color: "#64748b"; font.pixelSize: 7; font.bold: true }
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.gpuClock + "M"; color: "#4ade80"; font.pixelSize: 11; font.bold: true }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 38
                  radius: 6
                  color: "#121b27"
                  border.color: "#1d2e42"
                  border.width: 1
                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: "TDP"; color: "#64748b"; font.pixelSize: 7; font.bold: true }
                    Text { Layout.alignment: Qt.AlignHCenter; textFormat: Text.PlainText; text: root.tdpLimit + "W"; color: "#fbbf24"; font.pixelSize: 11; font.bold: true }
                  }
                }
              }

              // TDP Güç Sınırı Slider
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                  Layout.fillWidth: true
                  Text { textFormat: Text.PlainText; text: "TDP Güç Sınırı"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  Item { Layout.fillWidth: true }
                  Text { textFormat: Text.PlainText; text: root.tdpLimit + " Watt"; color: "#fbbf24"; font.pixelSize: 10; font.bold: true }
                }
                CustomSlider {
                  Layout.fillWidth: true
                  from: 3
                  to: 15
                  value: root.tdpLimit
                  onMoved: function(v) { root.tdpLimit = Math.round(v) }
                }
              }

              // FPS Sınırı Buttons
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                RowLayout {
                  Layout.fillWidth: true
                  Text { textFormat: Text.PlainText; text: "Kare Hızı Sınırı (FPS)"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  Item { Layout.fillWidth: true }
                  Text { textFormat: Text.PlainText; text: root.fpsLimit === 0 ? "Limitsiz" : root.fpsLimit + " FPS"; color: "#38bdf8"; font.pixelSize: 10; font.bold: true }
                }
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 4
                  Repeater {
                    model: [ { v: 30, t: "30" }, { v: 40, t: "40" }, { v: 60, t: "60" }, { v: 0, t: "Limitsiz" } ]
                    Rectangle {
                      required property var modelData
                      readonly property bool sel: root.fpsLimit === modelData.v
                      Layout.fillWidth: true
                      Layout.preferredHeight: 24
                      radius: 5
                      color: sel ? "#1a9fff" : "#131d2a"
                      border.color: sel ? "#66c0f4" : "#24364c"
                      border.width: 1
                      Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.t; color: sel ? "#ffffff" : "#cbd5e1"; font.pixelSize: 9; font.bold: sel }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.fpsLimit = modelData.v }
                    }
                  }
                }
              }

              // Termal / Güç Profili (Sessiz, Dengeli, Turbo)
              RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                  model: [ { v: 0, t: "󰤄 Sessiz" }, { v: 1, t: "󰓅 Dengeli" }, { v: 2, t: "󰓅 Turbo" } ]
                  Rectangle {
                    required property var modelData
                    readonly property bool sel: root.fanProfile === modelData.v
                    Layout.fillWidth: true
                    Layout.preferredHeight: 25
                    radius: 5
                    color: sel ? "#1a9fff" : "#131d2a"
                    border.color: sel ? "#66c0f4" : "#24364c"
                    border.width: 1
                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.t; color: sel ? "#ffffff" : "#cbd5e1"; font.pixelSize: 9; font.bold: sel }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.fanProfile = modelData.v }
                  }
                }
              }

              // MangoHud Bilgi Düzeyi
              RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { textFormat: Text.PlainText; text: "MangoHud:"; color: "#94a3b8"; font.pixelSize: 9; font.bold: true }
                Repeater {
                  model: [ { v: 0, t: "Kapalı" }, { v: 1, t: "1" }, { v: 2, t: "2" }, { v: 3, t: "3" }, { v: 4, t: "4" } ]
                  Rectangle {
                    required property var modelData
                    readonly property bool sel: root.overlayLevel === modelData.v
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 4
                    color: sel ? "#a855f7" : "#131d2a"
                    border.color: sel ? "#c084fc" : "#24364c"
                    border.width: 1
                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData.t; color: sel ? "#ffffff" : "#cbd5e1"; font.pixelSize: 8; font.bold: sel }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.overlayLevel = modelData.v }
                  }
                }
              }
            }
          }

          // ----------------------------------------------------
          // WIDGET 2: STEAM DECK OYUN & İSTEMCİ MERKEZİ
          // ----------------------------------------------------
          Rectangle {
            id: steamWidgetCard
            width: parent.width
            height: 236
            radius: 14
            color: "#f0090e17"
            border.color: "#1e344e"
            border.width: 1.5

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              // Header with Steam Logo
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                  Layout.preferredWidth: 28
                  Layout.preferredHeight: 28
                  radius: 7
                  color: "#102338"
                  border.color: "#1a9fff"
                  border.width: 1
                  Image {
                    anchors.centerIn: parent
                    source: "file:///home/omarchy/.config/omarchy/plugins/steamos-desktop/steam-logo-256.png"
                    width: 20
                    height: 20
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text {
                    textFormat: Text.PlainText
                    text: "STEAM OYUN & İSTEMCİ"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.1
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: "Proton & Hızlı Erişim"
                    color: "#66c0f4"
                    font.pixelSize: 9
                  }
                }
              }

              // Big Picture Hero Launch Button
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 8
                gradient: Gradient {
                  orientation: Gradient.Horizontal
                  GradientStop { position: 0.0; color: "#0284c7" }
                  GradientStop { position: 1.0; color: "#00b4d8" }
                }
                border.color: "#38bdf8"
                border.width: 1

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 8
                  Text { textFormat: Text.PlainText; text: "󰊗"; color: "#ffffff"; font.pixelSize: 16 }
                  Text { textFormat: Text.PlainText; text: "STEAM BIG PICTURE (GAMEPADUI)"; color: "#ffffff"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.runCmd("steamos-menu-action bigpicture")
                }
              }

              // Quick Buttons (Kütüphane & Mağaza)
              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 30
                  radius: 6
                  color: "#131d2a"
                  border.color: "#24364c"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { textFormat: Text.PlainText; text: "󰺵"; color: "#38bdf8"; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: "Kütüphane"; color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCmd("steamos-menu-action library")
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 30
                  radius: 6
                  color: "#131d2a"
                  border.color: "#24364c"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { textFormat: Text.PlainText; text: "󰄗"; color: "#a855f7"; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: "Mağaza"; color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCmd("steamos-menu-action store")
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 30
                  radius: 6
                  color: "#131d2a"
                  border.color: "#24364c"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { textFormat: Text.PlainText; text: "󰑐"; color: "#10b981"; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: "Yenile"; color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCmd("pkill -x steam; sleep 1; steam &")
                  }
                }
              }

              // Proton Uyumluluk Seçici
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text { textFormat: Text.PlainText; text: "Varsayılan Proton Sürümü:"; color: "#94a3b8"; font.pixelSize: 9; font.bold: true }
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 4
                  Repeater {
                    model: [ "Proton Experimental", "GE-Proton9", "Proton 9.0" ]
                    Rectangle {
                      required property string modelData
                      readonly property bool sel: root.protonVer === modelData
                      Layout.fillWidth: true
                      Layout.preferredHeight: 24
                      radius: 5
                      color: sel ? "#1a9fff" : "#131d2a"
                      border.color: sel ? "#66c0f4" : "#24364c"
                      border.width: 1
                      Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData; color: sel ? "#ffffff" : "#cbd5e1"; font.pixelSize: 8; font.bold: sel }
                      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.protonVer = modelData }
                    }
                  }
                }
              }

              // Shader Pre-Caching Toggle
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 6
                color: "#111a26"
                border.color: "#1d2e42"
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 6

                  Text { textFormat: Text.PlainText; text: "󰞏"; color: "#00d2ff"; font.pixelSize: 13 }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { textFormat: Text.PlainText; text: "Gölgelendirici Ön Bellek (Shader Pre-Cache)"; color: "#ffffff"; font.pixelSize: 9; font.bold: true }
                    Text { textFormat: Text.PlainText; text: "Oyun içi takılmaları önler"; color: "#64748b"; font.pixelSize: 8 }
                  }
                  CustomSwitch {
                    checked: root.shaderPreCache
                    onToggled: root.shaderPreCache = checked
                  }
                }
              }
            }
          }

          // ----------------------------------------------------
          // WIDGET 3: SİSTEM DENETİMİ, MEDYA & GÜÇ AYGITI
          // ----------------------------------------------------
          Rectangle {
            id: systemWidgetCard
            width: parent.width
            height: 304
            radius: 14
            color: "#f0090e17"
            border.color: "#1e344e"
            border.width: 1.5

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 8

              // Header
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                  Layout.preferredWidth: 28
                  Layout.preferredHeight: 28
                  radius: 7
                  color: "#102338"
                  border.color: "#38bdf8"
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: "󰒓"
                    color: "#38bdf8"
                    font.pixelSize: 15
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text {
                    textFormat: Text.PlainText
                    text: "SİSTEM KONTROL & GÜÇ"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.1
                  }
                  Text {
                    textFormat: Text.PlainText
                    text: "Ses, Ekran & Donanım Denetimi"
                    color: "#94a3b8"
                    font.pixelSize: 9
                  }
                }
              }

              // Ses Kontrolü (Volume)
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                  Layout.fillWidth: true
                  Text { textFormat: Text.PlainText; text: "Ana Ses Çıkışı"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  Item { Layout.fillWidth: true }
                  Text { textFormat: Text.PlainText; text: root.isMuted ? "Sessiz" : "%" + root.volumeLevel; color: "#38bdf8"; font.pixelSize: 10; font.bold: true }
                }
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 6
                  Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 5
                    color: root.isMuted ? "#dc2626" : "#162334"
                    border.color: root.isMuted ? "#ef4444" : "#24364c"
                    border.width: 1
                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: root.isMuted ? "󰝟" : "󰕾"; color: "#ffffff"; font.pixelSize: 12 }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.isMuted = !root.isMuted
                        root.runCmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                      }
                    }
                  }
                  CustomSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: root.volumeLevel
                    onMoved: function(v) {
                      root.volumeLevel = Math.round(v)
                      root.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + root.volumeLevel + "%")
                    }
                  }
                }
              }

              // Ekran Parlaklığı & Gece Işığı
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                RowLayout {
                  Layout.fillWidth: true
                  Text { textFormat: Text.PlainText; text: "Ekran Parlaklığı"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  Item { Layout.fillWidth: true }
                  Text { textFormat: Text.PlainText; text: "%" + root.brightnessLevel; color: "#fbbf24"; font.pixelSize: 10; font.bold: true }
                }
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 6
                  Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 5
                    color: root.nightLight ? "#ea580c" : "#162334"
                    border.color: root.nightLight ? "#f97316" : "#24364c"
                    border.width: 1
                    Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: "󰖔"; color: "#ffffff"; font.pixelSize: 12 }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.nightLight = !root.nightLight
                        root.runCmd("omarchy toggle nightlight")
                      }
                    }
                  }
                  CustomSlider {
                    Layout.fillWidth: true
                    from: 10
                    to: 100
                    value: root.brightnessLevel
                    onMoved: function(v) {
                      root.brightnessLevel = Math.round(v)
                      root.runCmd("brightnessctl set " + root.brightnessLevel + "%")
                    }
                  }
                }
              }

              // Ekran Yenileme Hızı & Ağ
              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Yenileme Hızı
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 34
                  radius: 6
                  color: "#121b27"
                  border.color: "#1d2e42"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { textFormat: Text.PlainText; text: "Hz:"; color: "#64748b"; font.pixelSize: 9; font.bold: true }
                    Repeater {
                      model: [ 40, 60 ]
                      Rectangle {
                        required property int modelData
                        readonly property bool sel: root.refreshRate === modelData
                        width: 44
                        height: 22
                        radius: 4
                        color: sel ? "#1a9fff" : "#1a2838"
                        border.color: sel ? "#66c0f4" : "#2a3d52"
                        border.width: 1
                        Text { anchors.centerIn: parent; textFormat: Text.PlainText; text: modelData + "Hz"; color: sel ? "#ffffff" : "#cbd5e1"; font.pixelSize: 8; font.bold: sel }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.refreshRate = modelData }
                      }
                    }
                  }
                }

                // Bluetooth Toggle Chip
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 34
                  radius: 6
                  color: "#121b27"
                  border.color: "#1d2e42"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { textFormat: Text.PlainText; text: "󰂯"; color: root.bluetoothOn ? "#38bdf8" : "#64748b"; font.pixelSize: 13 }
                    Text { textFormat: Text.PlainText; text: "BT"; color: "#cbd5e1"; font.pixelSize: 9; font.bold: true }
                    CustomSwitch {
                      checked: root.bluetoothOn
                      onToggled: {
                        root.bluetoothOn = checked
                        root.runCmd("rfkill " + (checked ? "unblock" : "block") + " bluetooth")
                      }
                    }
                  }
                }
              }

              // 3 Büyük Güç Butonu (Uyku, Yeniden, Kapat)
              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 36
                  radius: 7
                  color: "#162334"
                  border.color: "#2a4365"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { textFormat: Text.PlainText; text: "󰤄"; color: "#93c5fd"; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: "Uyku"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCmd("systemctl suspend")
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 36
                  radius: 7
                  color: "#1e293b"
                  border.color: "#334155"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { textFormat: Text.PlainText; text: "󰑐"; color: "#f59e0b"; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: "Yeniden"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCmd("systemctl reboot")
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 36
                  radius: 7
                  color: "#450a0a"
                  border.color: "#ef4444"
                  border.width: 1
                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { textFormat: Text.PlainText; text: "⏻"; color: "#f87171"; font.pixelSize: 12 }
                    Text { textFormat: Text.PlainText; text: "Kapat"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runCmd("systemctl poweroff")
                  }
                }
              }

              // Status line
              RowLayout {
                Layout.fillWidth: true
                spacing: 5
                Rectangle { width: 5; height: 5; radius: 2.5; color: "#22c55e" }
                Text { textFormat: Text.PlainText; text: root.statusMsg; color: "#64748b"; font.pixelSize: 8 }
              }
            }
          }
        }
      }

      // ==================== DESKTOP ICON REUSABLE COMPONENT ====================
      component DesktopIcon: Item {
        id: iconRoot
        property int idx: 0
        property string glyph: "󰋜"
        property color iconCol: "#38bdf8"
        property string badge: ""
        property string label: ""
        property string sublabel: ""
        signal launched()

        readonly property bool isSel: window.selectedIcon === iconRoot.idx

        width: 88
        height: 88

        Rectangle {
          anchors.fill: parent
          radius: 12
          color: iconRoot.isSel ? "#331a9fff" : (iconMouse.containsMouse ? "#2038bdf8" : "transparent")
          border.color: iconRoot.isSel ? "#66c0f4" : (iconMouse.containsMouse ? "#3338bdf8" : "transparent")
          border.width: 1
        }

        Rectangle {
          id: iconBox
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 4
          width: 52
          height: 52
          radius: 14
          color: iconMouse.containsMouse ? "#441a2736" : "#280f1724"
          border.color: iconMouse.containsMouse ? iconRoot.iconCol : "#333b82f6"
          border.width: iconMouse.containsMouse ? 2 : 1
          scale: iconMouse.pressed ? 0.92 : (iconMouse.containsMouse ? 1.08 : 1.0)

          Behavior on scale { NumberAnimation { duration: 120 } }

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: iconRoot.glyph
            color: iconRoot.iconCol
            font.pixelSize: 26
          }

          Rectangle {
            visible: iconRoot.badge !== ""
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
            width: 26
            height: 14
            radius: 6
            color: "#1a9fff"
            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: iconRoot.badge
              color: "#ffffff"
              font.pixelSize: 8
              font.bold: true
            }
          }
        }

        Text {
          anchors.top: iconBox.bottom
          anchors.topMargin: 4
          anchors.horizontalCenter: parent.horizontalCenter
          textFormat: Text.PlainText
          text: iconRoot.label
          color: iconRoot.isSel ? "#38bdf8" : (iconMouse.containsMouse ? "#ffffff" : "#f1f5f9")
          font.pixelSize: 10
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          style: Text.Outline
          styleColor: "#e6000000"
        }

        MouseArea {
          id: iconMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            window.selectedIcon = iconRoot.idx
            iconRoot.launched()
          }
          onDoubleClicked: {
            iconRoot.launched()
          }
        }

        ToolTip {
          visible: iconMouse.containsMouse && iconRoot.sublabel !== ""
          text: iconRoot.sublabel
          delay: 300
          timeout: 2500
        }
      }

      // ==================== CUSTOM SLEEK SWITCH COMPONENT ====================
      component CustomSwitch: Item {
        id: switchRoot
        property bool checked: false
        signal toggled()

        implicitWidth: 42
        implicitHeight: 22

        Rectangle {
          anchors.fill: parent
          radius: 11
          color: switchRoot.checked ? "#1a9fff" : "#1a2736"
          border.color: switchRoot.checked ? "#66c0f4" : "#33455b"
          border.width: 1

          Behavior on color { ColorAnimation { duration: 150 } }

          Rectangle {
            x: switchRoot.checked ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: "#ffffff"

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: switchRoot.toggled()
        }
      }

      // ==================== CUSTOM SLEEK SLIDER COMPONENT ====================
      component CustomSlider: Item {
        id: sliderRoot
        property real from: 0
        property real to: 100
        property real value: 50
        signal moved(real val)

        implicitWidth: 180
        implicitHeight: 22

        readonly property real ratio: Math.max(0, Math.min(1, (sliderRoot.value - sliderRoot.from) / Math.max(1, sliderRoot.to - sliderRoot.from)))

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          height: 5
          radius: 2.5
          color: "#162334"
          border.color: "#243b55"
          border.width: 1

          Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * sliderRoot.ratio
            color: "#1a9fff"
          }
        }

        Rectangle {
          x: (sliderRoot.ratio * Math.max(0, sliderRoot.width - width))
          anchors.verticalCenter: parent.verticalCenter
          width: 16
          height: 16
          radius: 8
          color: "#ffffff"
          border.color: "#1a9fff"
          border.width: 2
          scale: sMouse.pressed ? 1.2 : (sMouse.containsMouse ? 1.1 : 1.0)

          Behavior on scale { NumberAnimation { duration: 100 } }
        }

        MouseArea {
          id: sMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          function updatePos(mx) {
            var r = Math.max(0, Math.min(1, mx / width))
            var val = sliderRoot.from + r * (sliderRoot.to - sliderRoot.from)
            sliderRoot.moved(val)
          }
          onPressed: function(mouse) { updatePos(mouse.x) }
          onPositionChanged: function(mouse) { if (pressed) updatePos(mouse.x) }
        }
      }
    }
  }
}
