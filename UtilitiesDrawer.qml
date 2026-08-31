import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var host: null
  property bool opened: false
  property real cpuUsage: 0
  property real memUsage: 0
  property var prevCpu: null

  readonly property color foreground: Color.menu.text
  readonly property color accent: Color.accent
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"

  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight
  width: parent ? parent.width : implicitWidth
  height: implicitHeight
  opacity: opened ? 1 : 0
  visible: opacity > 0.02
  Behavior on opacity { NumberAnimation { duration: 160 } }

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

  Column {
    id: col
    width: root.width
    spacing: Style.space(8)

    Text {
      text: "SYS  //  STATUS"
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.letterSpacing: 1.6
      font.bold: true
    }

    Text {
      text: "CPU  " + root.pct(root.cpuUsage)
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }
    Rectangle {
      width: parent.width
      height: 7
      color: Qt.rgba(1, 1, 1, 0.08)
      Rectangle {
        width: Math.max(2, parent.width * root.cpuUsage)
        height: parent.height
        color: root.cpuUsage >= 0.85 ? Color.urgent : root.accent
      }
    }

    Text {
      text: "MEM  " + root.pct(root.memUsage)
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }
    Rectangle {
      width: parent.width
      height: 7
      color: Qt.rgba(1, 1, 1, 0.08)
      Rectangle {
        width: Math.max(2, parent.width * root.memUsage)
        height: parent.height
        color: root.memUsage >= 0.85 ? Color.urgent : "#A8FF3E"
      }
    }

    Repeater {
      model: [
        { label: "NIGHT LIGHT", cmd: ["omarchy", "toggle", "nightlight"] },
        { label: "STAY AWAKE", cmd: ["omarchy", "toggle", "idle"] },
        { label: "SILENCE", cmd: ["omarchy", "toggle", "notification", "silencing"] },
        { label: "NEXT WALL", cmd: ["omarchy", "theme", "bg", "next"] }
      ]
      Rectangle {
        required property var modelData
        width: parent.width
        height: Style.space(30)
        radius: 0
        color: cell.containsMouse ? Qt.rgba(1, 0.42, 0, 0.22) : Qt.rgba(1, 1, 1, 0.04)
        border.width: cell.containsMouse ? 1 : 0
        border.color: "#FF6A00"
        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: root.foreground
          font.family: root.fontFamily
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
