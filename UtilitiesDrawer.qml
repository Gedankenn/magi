import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var host: null
  property bool opened: false
  property string cpuTemp: ""
  property string gpuTemp: ""
  property string gpuUsage: ""
  property string upTime: ""

  property string netIp: ""
  property string netIface: ""
  property string netGateway: ""
  property string netSsid: ""
  property bool netConnected: false
  property real rxRate: 0
  property real txRate: 0
  property real prevRx: 0
  property real prevTx: 0
  property real ratePrevTime: 0

  readonly property color paper: "#F4F0E6"
  readonly property color muted: "#8a7a6e"
  readonly property color accent: "#FF6A00"
  readonly property color acid: "#A8FF3E"
  readonly property color blood: "#C41E3A"
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
  readonly property string displayFont: host && host.displayFont ? host.displayFont : "Chakra Petch"

  width: parent ? parent.width : 320
  height: parent ? parent.height : 300
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
    cpuTemp = map.tcpu || ""
    gpuTemp = map.tgpu || ""
    gpuUsage = map.gpu || ""
    upTime = map.up || ""
    netIp = map.ip || ""
    netIface = map.iface || ""
    netGateway = map.gw || ""
    netSsid = map.ssid || ""
    netConnected = map.state === "connected"
    var rx = parseInt(map.rx) || 0
    var tx = parseInt(map.tx) || 0
    var now = Date.now()
    if (root.prevRx > 0 && root.prevTx > 0 && now > root.ratePrevTime) {
      var dt = (now - root.ratePrevTime) / 1000
      if (dt > 0) {
        root.rxRate = Math.max(0, (rx - root.prevRx) / dt)
        root.txRate = Math.max(0, (tx - root.prevTx) / dt)
      }
    }
    root.prevRx = rx
    root.prevTx = tx
    root.ratePrevTime = now
  }

  function fmtRate(bytes) {
    if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB/s"
    return Math.round(bytes / 1024) + " KB/s"
  }

  function run(args) {
    if (!args || !args.length) return
    Quickshell.execDetached(args)
  }

  onOpenedChanged: if (opened && !statsProc.running) statsProc.running = true

  Process {
    id: statsProc
    command: ["sh", "-c", "IFACE=$(ip -4 route show default | awk '{print $5; exit}'); echo tcpu=$(sensors 2>/dev/null | awk '/k10temp/{f=1;next} f&&/Tctl:/{gsub(/[^0-9.]/,\"\",$2); print $2; exit}'); echo tgpu=$(sensors 2>/dev/null | awk '/amdgpu-pci-0300/{f=1;next} f&&/edge:/{gsub(/[^0-9.]/,\"\",$2); print $2; exit}'); echo gpu=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null); echo up=$(uptime -p | sed 's/up //' | tr -d '\\n'); echo ip=$(ip -4 -brief addr show scope global | awk '{print $3}' | cut -d/ -f1); echo iface=$IFACE; echo gw=$(ip -4 route show default | awk '{print $3; exit}'); echo ssid=$(nmcli -t -f NAME con show --active 2>/dev/null | head -1); echo state=$(nmcli -t -f STATE g 2>/dev/null); echo rx=$(awk -v i=\"$IFACE\" '$1 ~ i \":\" {print $2}' /proc/net/dev); echo tx=$(awk -v i=\"$IFACE\" '$1 ~ i \":\" {print $10}' /proc/net/dev)"]
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
    anchors.fill: parent
    anchors.margins: 14
    spacing: 6

    Item {
      width: parent.width
      height: 15
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "NETWORK"
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 13
        font.letterSpacing: 2.5
        font.weight: 600
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.netConnected ? "LINK UP" : "OFFLINE"
        color: root.netConnected ? root.acid : root.blood
        font.family: root.displayFont
        font.pixelSize: 11
        font.letterSpacing: 1.5
        font.weight: 600
      }
    }
    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(1, 0.42, 0, 0.35)
    }

    Grid {
      columns: 2
      width: parent.width
      columnSpacing: 16
      rowSpacing: 3

      Text { text: "IFACE"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; width: 56 }
      Text { text: root.netIface || "—"; color: root.paper; horizontalAlignment: Text.AlignRight; width: (parent.width - parent.columnSpacing)/2 - 56; font.family: root.fontFamily; font.pixelSize: 12 }
      Text { text: "IP"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; width: 56 }
      Text { text: root.netIp || "—"; color: root.paper; horizontalAlignment: Text.AlignRight; width: (parent.width - parent.columnSpacing)/2 - 56; font.family: root.fontFamily; font.pixelSize: 12 }
      Text { text: "GATEWAY"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; width: 56 }
      Text { text: root.netGateway || "—"; color: root.paper; horizontalAlignment: Text.AlignRight; width: (parent.width - parent.columnSpacing)/2 - 56; font.family: root.fontFamily; font.pixelSize: 12 }
      Text { text: "LINK"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; width: 56 }
      Text {
        text: root.netSsid || "—"
        color: root.paper
        horizontalAlignment: Text.AlignRight
        width: (parent.width - parent.columnSpacing)/2 - 56
        font.family: root.fontFamily
        font.pixelSize: 12
        elide: Text.ElideMiddle
      }
      Text { text: "DOWN"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; width: 56 }
      Text { text: root.fmtRate(root.rxRate); color: root.rxRate > 0 ? root.acid : root.muted; horizontalAlignment: Text.AlignRight; width: (parent.width - parent.columnSpacing)/2 - 56; font.family: root.fontFamily; font.pixelSize: 12 }
      Text { text: "UP"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; width: 56 }
      Text { text: root.fmtRate(root.txRate); color: root.txRate > 0 ? root.acid : root.muted; horizontalAlignment: Text.AlignRight; width: (parent.width - parent.columnSpacing)/2 - 56; font.family: root.fontFamily; font.pixelSize: 12 }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(1, 0.42, 0, 0.35)
    }

    Row {
      width: parent.width
      Text {
        text: "THERMAL"
        color: root.muted
        font.family: root.displayFont
        font.pixelSize: 10
        font.letterSpacing: 2
      }
      Item { width: 10; height: 1 }
      Text {
        text: "UPTIME " + root.upTime.toUpperCase()
        color: root.paper
        font.family: root.fontFamily
        font.pixelSize: 12
        font.bold: true
        font.letterSpacing: 0.6
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Row {
      width: parent.width
      Text {
        text: "CPU TEMP  " + root.cpuTemp + "\u00b0C"
        color: root.paper
        font.family: root.fontFamily
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 1.2
      }
      Item { width: 10; height: 1 }
      Text {
        text: "RX5600XT  " + root.gpuTemp + "\u00b0C"
        color: root.acid
        font.family: root.fontFamily
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 1.2
        anchors.verticalCenter: parent.verticalCenter
      }
    }
    Rectangle {
      width: parent.width
      height: 9
      color: "#2a1510"
      Rectangle {
        width: Math.max(3, parent.width * (parseFloat(root.cpuTemp) || 0) / 100)
        height: parent.height
        color: (parseFloat(root.cpuTemp) || 0) >= 80 ? root.blood : root.accent
      }
    }
    Rectangle {
      width: parent.width
      height: 9
      color: "#2a1510"
      Rectangle {
        width: Math.max(3, parent.width * (parseFloat(root.gpuTemp) || 0) / 100)
        height: parent.height
        color: (parseFloat(root.gpuTemp) || 0) >= 80 ? root.blood : root.acid
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
        height: 28
        color: cell.containsMouse ? Qt.rgba(1, 0.42, 0, 0.22) : "#141014"
        border.width: 1
        border.color: cell.containsMouse ? root.accent : Qt.rgba(1, 0.42, 0, 0.28)
        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: root.paper
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 1.8
          font.weight: 600
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
