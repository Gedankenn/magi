import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.performance"

  property real cpuUsage: 0
  property real memUsage: 0
  property real diskUsage: 0
  property var prevCpu: null

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
    diskUsage = Math.max(0, Math.min(1, (parseInt(map.disk) || 0) / 100))
  }

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  readonly property string label: "CPU " + root.pct(root.cpuUsage) + "  MEM " + root.pct(root.memUsage) + "  DISK " + root.pct(root.diskUsage)

  implicitWidth: row.implicitWidth + 16
  implicitHeight: Math.max(30, row.implicitHeight + 4)

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statsProc
    command: ["sh", "-c", "echo cpu=$(grep '^cpu ' /proc/stat); echo mem=$(awk '/MemTotal:|MemAvailable:/{print}' /proc/meminfo); echo disk=$(df -P / | awk 'NR==2{print $5}')"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStats(text)
    }
  }

  readonly property string displayFont: "Chakra Petch"
  readonly property string bodyFont: "Nimbus Sans Narrow"

  function meterColor(value) {
    if (value >= 0.85) return "#C41E3A"
    if (value >= 0.6) return "#FF6A00"
    return "#A8FF3E"
  }

  function fmt(value) { return Math.round((value || 0) * 100) + "%" }

  component MeterCell: Item {
    required property string name
    required property string value
    required property color valueColor
    required property string displayFont
    required property string bodyFont
    width: 58
    height: cellText.implicitHeight

    Text {
      id: nameText
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: parent.name
      color: "#9A8B7C"
      font.family: parent.displayFont
      font.pixelSize: 12
      font.weight: 500
      font.letterSpacing: 1
      font.capitalization: Font.AllUppercase
    }
    Text {
      id: cellText
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: parent.value
      color: parent.valueColor
      font.family: parent.bodyFont
      font.pixelSize: 14
      font.weight: Font.Bold
      font.letterSpacing: 0.5
      width: 34
      horizontalAlignment: Text.AlignRight
    }
  }

  Item {
    id: labelRow
    anchors.centerIn: parent
    height: row.implicitHeight

    Row {
      id: row
      spacing: 6
      anchors.centerIn: parent

      MeterCell { name: "CPU";  value: root.fmt(root.cpuUsage);  valueColor: root.meterColor(root.cpuUsage);            displayFont: root.displayFont; bodyFont: root.bodyFont }
      MeterCell { name: "MEM";  value: root.fmt(root.memUsage);  valueColor: root.memUsage >= 0.85 ? "#C41E3A" : root.memUsage >= 0.6 ? "#FF6A00" : "#e8dcc8"; displayFont: root.displayFont; bodyFont: root.bodyFont }
      MeterCell { name: "DISK"; value: root.fmt(root.diskUsage); valueColor: root.diskUsage >= 0.85 ? "#C41E3A" : "#e8dcc8"; displayFont: root.displayFont; bodyFont: root.bodyFont }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, "CPU " + root.pct(root.cpuUsage) + " · Memory " + root.pct(root.memUsage) + " · Disk " + root.pct(root.diskUsage))
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: root.refresh()
  }
}
