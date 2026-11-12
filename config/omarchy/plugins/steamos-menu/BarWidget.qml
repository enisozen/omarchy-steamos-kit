import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "steamos.menu"

  implicitWidth: contentRow.implicitWidth + Style.space(16)
  implicitHeight: barSize

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.space(6)
    scale: mouseArea.pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }

    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: "󰓓"
      color: root.bar ? root.bar.barForeground : Commons.Color.foreground
      font.pixelSize: Style.bar.iconSize
    }

    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: "SteamOS"
      color: root.bar ? root.bar.barForeground : Commons.Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (!root.bar) return
      if (mouse.button === Qt.RightButton) {
        root.bar.run("xdg-terminal-exec")
      } else {
        root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
      }
    }
  }
}
