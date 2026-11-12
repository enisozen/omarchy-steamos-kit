import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "steamos.workspaces"

  readonly property int slots: 10

  readonly property var monitor: {
    var window = root.QsWindow.window
    var screen = window ? window.screen : null
    return screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  }
  readonly property string monitorName: root.monitor ? root.monitor.name : ""

  property var blocks: ({})

  function readBlocks(text) {
    var next = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].split("\t")
      if (fields.length >= 3 && fields[1] !== "") next[fields[1]] = parseInt(fields[0], 10)
    }
    root.blocks = next
  }

  FileView {
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/monitor-workspaces"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.readBlocks(text())
    onLoadFailed: root.readBlocks("")
  }

  function blockOf(id) {
    return Math.floor((id - 1) / root.slots)
  }

  function slotOf(id) {
    return (id - 1) % root.slots + 1
  }

  function activeWorkspaceId() {
    return root.monitor && root.monitor.activeWorkspace ? root.monitor.activeWorkspace.id : -1
  }

  readonly property int block: {
    var block = root.blocks[root.monitorName]
    if (block !== undefined) return block
    var active = root.activeWorkspaceId()
    return active > 0 ? root.blockOf(active) : 0
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function workspaceIds() {
    var base = root.block * root.slots
    var ids = [base + 1, base + 2, base + 3, base + 4, base + 5]
    var guests = []
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id <= 0) continue
      if (root.blockOf(id) === root.block) {
        if (ids.indexOf(id) === -1) ids.push(id)
      } else if (values[i].monitor && values[i].monitor.name === root.monitorName) {
        guests.push(id)
      }
    }

    ids.sort(function(left, right) { return left - right })
    guests.sort(function(left, right) { return left - right })
    return ids.concat(guests)
  }

  function dispatch(expression) {
    if (root.bar) root.bar.run("hyprctl dispatch " + Util.shellQuote(expression))
  }

  function focusWorkspace(id) {
    if (root.blockOf(id) === root.block) {
      root.dispatch("o.workspaces.focus(" + root.slotOf(id) + ", \"" + root.monitorName + "\")")
    } else {
      root.dispatch("hl.dsp.focus({ workspace = \"" + id + "\" })")
    }
  }

  property real wheelAccumulator: 0

  function scrollWorkspaces(delta) {
    var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
    root.wheelAccumulator = wheel.remainder
    if (wheel.steps === 0) return

    var ids = root.workspaceIds()
    var index = ids.indexOf(root.activeWorkspaceId())
    if (index === -1) return
    var target = ids[Util.clamp(index - wheel.steps, 0, ids.length - 1)]
    if (target !== ids[index]) root.focusWorkspace(target)
  }

  property string activeMode: "dwindle"
  property bool modeStale: false

  function modeGlyph(mode) {
    if (mode === "scrolling") return "󰝥"
    if (mode === "floating") return "󰔶"
    return "󱓻"
  }

  property var modeCache: ({})
  property int modeGeneration: 0
  property int modeProcWorkspace: -1
  property int modeProcGeneration: 0

  function showActiveMode() {
    var mode = root.modeCache[root.activeWorkspaceId()]
    if (mode !== undefined) root.activeMode = mode
    else readMode()
  }

  function readMode() {
    if (modeProc.running) {
      root.modeStale = true
      return
    }
    var id = root.activeWorkspaceId()
    if (id === -1) return
    root.modeProcWorkspace = id
    root.modeProcGeneration = root.modeGeneration
    modeProc.command = ["omarchy-hyprland-workspace-layout-current", String(id)]
    modeProc.running = true
  }

  function refresh() {
    root.modeCache = ({})
    root.modeGeneration++
    readMode()
  }

  function cycleLayout() {
    if (!root.bar) return
    var command = "omarchy-hyprland-workspace-layout-toggle"
    if (root.monitor && !root.monitor.focused) {
      command = "hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ monitor = \"" + root.monitorName + "\" })") + " >/dev/null && " + command
    }
    root.bar.run(command)
  }

  Component.onCompleted: refresh()
  onMonitorChanged: root.showActiveMode()

  Connections {
    target: root.monitor
    function onActiveWorkspaceChanged() { root.showActiveMode() }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      if (name === "configreloaded") root.refresh()
      var switched = name === "workspacev2" && root.monitor !== null && root.monitor.focused
      if (switched || name === "moveworkspacev2" || name === "changeworkspaceid") {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
      }
    }
  }

  Process {
    id: modeProc
    stdout: StdioCollector {
      onStreamFinished: {
        var mode = text.trim()
        if (!mode || root.modeProcGeneration !== root.modeGeneration) return
        root.modeCache[root.modeProcWorkspace] = mode
        if (root.modeProcWorkspace === root.activeWorkspaceId()) root.activeMode = mode
      }
    }
    onExited: {
      if (!root.modeStale) return
      root.modeStale = false
      Qt.callLater(root.showActiveMode)
    }
  }

  ShellIpc {
    target: "omarchy.workspaces"
    function refresh(): void { root.broadcast("refresh") }
  }

  ShellIpc {
    target: "steamos.workspaces"
    function refresh(): void { root.broadcast("refresh") }
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: itemRoot
        required property int modelData
        required property int index

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool shown: root.monitor !== null && root.monitor.activeWorkspace !== null && root.monitor.activeWorkspace.id === modelData
        readonly property int slot: root.slotOf(modelData)
        readonly property bool isSteamOs: modelData === 1
        readonly property bool firstGuest: root.blockOf(modelData) !== root.block && index > 0 && root.blockOf(root.workspaceIds()[index - 1]) === root.block

        Layout.leftMargin: firstGuest && !root.vertical ? Style.space(6) : 0
        Layout.topMargin: firstGuest && root.vertical ? Style.space(6) : 0

        implicitWidth: isSteamOs ? steamOsBtn.implicitWidth : wsBtn.implicitWidth
        implicitHeight: root.barSize

        // 1. SteamOS Butonu (Masaüstü 1)
        WidgetButton {
          id: steamOsBtn
          visible: itemRoot.isSteamOs
          anchors.fill: parent
          bar: root.bar
          text: ""
          fixedWidth: steamRow.implicitWidth + Style.space(16)
          fixedHeight: root.barSize
          opacity: itemRoot.occupied || itemRoot.shown ? 1.0 : 0.6
          onPressed: function() {
            if (itemRoot.shown) root.cycleLayout()
            else root.focusWorkspace(1)
          }
          onWheelMoved: function(delta) { root.scrollWorkspaces(delta) }

          Row {
            id: steamRow
            anchors.centerIn: parent
            spacing: Style.space(5)
            scale: steamOsBtn.pressScale

            Text {
              textFormat: Text.PlainText
              anchors.verticalCenter: parent.verticalCenter
              text: "󰓓"
              color: steamOsBtn.active && steamOsBtn.useActiveColor ? steamOsBtn.activeColor : steamOsBtn.foreground
              font.pixelSize: Style.font.body + 2
            }

            Text {
              textFormat: Text.PlainText
              anchors.verticalCenter: parent.verticalCenter
              text: "SteamOS"
              color: steamOsBtn.active && steamOsBtn.useActiveColor ? steamOsBtn.activeColor : steamOsBtn.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              font.bold: itemRoot.shown
            }
          }
        }

        // 2. Normal Numaralı Masaüstü Butonları (Workspace 2 -> 1, Workspace 3 -> 2, ...)
        WidgetButton {
          id: wsBtn
          visible: !itemRoot.isSteamOs
          anchors.fill: parent
          bar: root.bar
          text: itemRoot.shown ? root.modeGlyph(root.activeMode) : String(itemRoot.slot - 1)
          opacity: itemRoot.occupied || itemRoot.shown ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: root.vertical ? root.barSize : Style.space(20)
          fixedHeight: root.barSize
          onPressed: function() {
            if (itemRoot.shown) root.cycleLayout()
            else root.focusWorkspace(itemRoot.modelData)
          }
          onWheelMoved: function(delta) { root.scrollWorkspaces(delta) }
        }
      }
    }
  }
}
