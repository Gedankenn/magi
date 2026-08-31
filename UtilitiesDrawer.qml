import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var screen
  required property var host
  property bool opened: false
  property bool hovered: false
  property real cpuUsage: 0
  property real memUsage: 0
  property var prevCpu: null

  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color accent: Color.accent
  readonly property var borderSpec: Border.flat("#FF6A00", 2)
  readonly property int cardWidth: Math.max(Math.round(host && host.rightIslandWidth ? host.rightIslandWidth : 0), Style.space(240))
  readonly property real shownY: {
    var gap = host && host.sideGap ? host.sideGap : Style.gapsOut
    var size = host && host.barSize ? host.barSize : Style.bar.sizeHorizontal
    return gap + size + 2
  }
  readonly property real shownX: Math.max(0, (panel.width || 1920) - cardWidth - (host && host.sideGap ? host.sideGap : Style.gapsOut))

  function pct(value) { return Math.round((value || 0) * 100) + "%" }

  function parseStats(raw) {
    var map = {}
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var cut = lines[i].indexOf("=")
      if (cut < 0) continue
      map[lines[i].slice(0, cut)] = lines[i].slice(cut + 1)
    }
    var c = String(map.cpu || "").trim().split(/\s+/)
    if (c.length >= 8) {
      var idle = parseInt(c[4]) || 0
      var total = (parseInt(c[1]) || 0) + (parseInt(c[2]) || 0) + (parseInt(c[3]) || 0)
        + idle + (parseInt(c[5]) || 0) + (parseInt(c[6]) || 0) + (parseInt(c[7]) || 0)
      if (prevCpu) {
        var dT = total - prevCpu.total
        var dI = idle - prevCpu.idle
        cpuUsage = dT > 0 ? Math.max(0, Math.min(1, 1 - dI / dT)) : 0
      }
      prevCpu = { total: total, idle: idle }
    }
    var mt = 0, ma = 0
    var mems = String(map.mem || "").match(/MemTotal:\s*\d+|MemAvailable:\s*\d+/g) || []
    for (var m = 0; m < mems.length; m++) {
      var bits = mems[m].split(/\s+/)
      if (bits[0] === "MemTotal:") mt = parseInt(bits[1]) || 0
      else if (bits[0] === "MemAvailable:") ma = parseInt(bits[1]) || 0
    }
    memUsage = mt > 0 ? Math.max(0, Math.min(1, (mt - ma) / mt)) : 0
  }

  function run(args) {
    if (!args || !args.length) return
    Quickshell.execDetached(args)
  }

  onOpenedChanged: if (opened && !statsProc.running) statsProc.running = true

  Process {
    id: statsProc
    command: ["sh", "-c", "echo cpu=$(grep '^cpu ' /proc/stat); echo mem=$(awk '/MemTotal:|MemAvailable:/{print}' /proc/meminfo)"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStats(text)
    }
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  PanelWindow {
    id: panel
    screen: root.screen
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-utilities"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: card }

    Rectangle {
      anchors.fill: card
      anchors.margins: -2
      radius: host && host.islandRadius !== undefined ? host.islandRadius : 0
      color: "transparent"
      border.width: 2
      border.color: "#FF6A00"
      opacity: 0.45
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: col.implicitHeight + Style.spacing.panelPadding * 2
      radius: host && host.islandRadius !== undefined ? host.islandRadius : 0
      x: root.shownX
      y: root.opened ? root.shownY : root.shownY - 16
      color: root.background
      borderSpec: root.borderSpec
      opacity: root.opened ? 1 : 0
      Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 160 } }

      HoverHandler { onHoveredChanged: root.hovered = hovered }

      Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.space(8)

        HazardStripe {
          width: parent.width
          height: 12
        }

        Text {
          text: "SYS  //  STATUS"
          color: root.accent
          font.family: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.6
          font.bold: true
        }

        Text {
          text: "CPU  " + root.pct(root.cpuUsage)
          color: root.foreground
          font.family: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
          font.pixelSize: Style.font.body
        }
        Rectangle {
          width: parent.width
          height: 7
          radius: 3
          color: Qt.rgba(1, 1, 1, 0.08)
          Rectangle {
            width: Math.max(2, parent.width * root.cpuUsage)
            height: parent.height
            radius: parent.radius
            color: root.cpuUsage >= 0.85 ? Color.urgent : root.accent
          }
        }

        Text {
          text: "MEM  " + root.pct(root.memUsage)
          color: root.foreground
          font.family: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
          font.pixelSize: Style.font.body
        }
        Rectangle {
          width: parent.width
          height: 7
          radius: 3
          color: Qt.rgba(1, 1, 1, 0.08)
          Rectangle {
            width: Math.max(2, parent.width * root.memUsage)
            height: parent.height
            radius: parent.radius
            color: root.memUsage >= 0.85 ? Color.urgent : "#A8FF3E"
          }
        }

        Repeater {
          model: [
            { label: "NIGHT LIGHT", cmd: ["omarchy", "toggle", "nightlight"] },
            { label: "STAY AWAKE", cmd: ["omarchy", "toggle", "idle"] },
            { label: "SILENCE", cmd: ["omarchy", "toggle", "notification", "silencing"] }
          ]
          Rectangle {
            required property var modelData
            width: parent.width
            height: Style.space(30)
            radius: 4
            color: cell.containsMouse ? Qt.rgba(1, 0.42, 0, 0.18) : Qt.rgba(1, 1, 1, 0.04)
            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: root.foreground
              font.family: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
              font.pixelSize: Style.font.bodySmall
              font.letterSpacing: 1.4
            }
            MouseArea {
              id: cell
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.run(modelData.cmd)
            }
          }
        }
      }
    }
  }
}
