import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

Item {
  id: root

  property var host: null
  property bool opened: false

  readonly property color paper: "#F4F0E6"
  readonly property color muted: "#9A8B7C"
  readonly property color accent: "#FF6A00"
  readonly property color blood: "#C41E3A"
  readonly property color acid: "#A8FF3E"
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"

  property string weatherEmoji: ""
  property string weatherTemp: ""
  property string weatherCond: ""
  property string weatherHum: ""
  property string weatherWind: ""
  property string weatherPlace: ""
  property string locationQuery: ""
  property real cpuUsage: 0
  property real memUsage: 0
  property real diskUsage: 0
  property var prevCpu: null

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: pickPlayer()
  readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property bool playing: !!(activePlayer && activePlayer.isPlaying)

  width: parent ? parent.width : 1600
  height: parent ? parent.height : 500
  opacity: opened ? 1 : 0
  visible: opacity > 0.02
  Behavior on opacity { NumberAnimation { duration: 140 } }

  function pickPlayer() {
    var list = players || []
    for (var i = 0; i < list.length; i++) {
      if (list[i] && (list[i].trackTitle || list[i].isPlaying)) return list[i]
    }
    return list.length ? list[0] : null
  }

  function refreshAll() {
    startWeather()
    if (!statsProc.running) statsProc.running = true
  }

  function startWeather() {
    weatherProc.command = ["curl", "-fsS", "-A", "magi-dashboard", "--max-time", "6",
      "https://wttr.in/" + String(root.locationQuery || "") + "?format=%c|%t|%C|%h|%w|%l&m"]
    weatherProc.running = true
  }

  function parseWeather(raw) {
    var parts = String(raw || "").replace(/\r/g, "").split("|")
    if (parts.length < 2) return
    weatherEmoji = String(parts[0] || "").trim()
    weatherTemp = String(parts[1] || "").trim().replace(/^\+/, "")
    weatherCond = String(parts[2] || "").trim()
    weatherHum = String(parts[3] || "").trim()
    weatherWind = String(parts[4] || "").trim()
    weatherPlace = String(parts[5] || "").trim()
  }

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

  function meterColor(value) {
    if (value >= 0.85) return blood
    if (value >= 0.6) return accent
    return acid
  }

  function pct(value) {
    return Math.round((value || 0) * 100) + "%"
  }

  function mediaAction(action) {
    if (!activePlayer) return
    if (action === "play") activePlayer.togglePlaying()
    else if (action === "next") activePlayer.next()
    else activePlayer.previous()
  }

  onOpenedChanged: if (opened) refreshAll()

  Connections {
    target: host
    function onDashSerialChanged() { root.refreshAll() }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var data = JSON.parse(text() || "{}")
        var lat = parseFloat(data.latitude)
        var lon = parseFloat(data.longitude)
        if (isFinite(lat) && isFinite(lon)) root.locationQuery = lat + "," + lon
        else root.locationQuery = String(data.name || "")
      } catch (e) {
        root.locationQuery = ""
      }
    }
  }

  Process {
    id: weatherProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseWeather(text)
    }
  }

  Process {
    id: statsProc
    command: ["sh", "-c", "echo cpu=$(grep '^cpu ' /proc/stat); echo mem=$(awk '/MemTotal:|MemAvailable:/{print}' /proc/meminfo); echo disk=$(df -P / | awk 'NR==2{print $5}')"]
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

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  component CorePane: Rectangle {
    id: pane
    property string coreId: "00"
    property string title: ""
    property alias body: paneBody
    color: "#120e10"
    border.width: 1
    border.color: "#5A2A10"

    Rectangle {
      width: 5
      anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
      color: root.accent
    }

    Text {
      id: paneHead
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.leftMargin: 22
      anchors.topMargin: 18
      text: pane.coreId + "   " + pane.title
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: 18
      font.bold: true
      font.letterSpacing: 1.5
    }

    Rectangle {
      id: paneRule
      anchors.top: paneHead.bottom
      anchors.topMargin: 12
      anchors.left: parent.left
      anchors.leftMargin: 22
      anchors.right: parent.right
      anchors.rightMargin: 18
      height: 1
      color: "#5A2A10"
    }

    Item {
      id: paneBody
      anchors.top: paneRule.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: 18
      anchors.leftMargin: 22
      anchors.rightMargin: 18
      anchors.bottomMargin: 18
    }
  }

  component Meter: Item {
    property string label: ""
    property real value: 0
    height: 58
    width: parent ? parent.width : 200

    Text {
      text: label
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: 16
      font.bold: true
    }
    Text {
      anchors.right: parent.right
      text: root.pct(value)
      color: root.paper
      font.family: root.fontFamily
      font.pixelSize: 22
      font.bold: true
    }
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 14
      color: "#2a1510"
      Rectangle {
        width: Math.max(6, parent.width * value)
        height: parent.height
        color: root.meterColor(value)
      }
    }
  }

  Item {
    id: topBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 72

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 24
      anchors.verticalCenter: parent.verticalCenter
      text: root.host && root.host.pinned ? "PINNED" : (root.weatherPlace || "GEOFRONT").toUpperCase()
      color: root.paper
      font.family: root.fontFamily
      font.pixelSize: 20
      font.bold: true
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 24
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatTime(clock.date, "HH:mm:ss")
      color: root.paper
      font.family: root.fontFamily
      font.pixelSize: 44
      font.bold: true
    }
  }

  Row {
    id: cores
    anchors.top: topBar.bottom
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 20
    spacing: 16

    CorePane {
      id: balthasar
      width: (parent.width - 32) / 3
      height: parent.height
      coreId: "01"
      title: "BALTHASAR"

      Column {
        parent: balthasar.body
        width: parent.width
        spacing: 14

        Text {
          text: (root.weatherTemp || "—") + "   " + (root.weatherEmoji || "")
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 48
          font.bold: true
        }
        Text {
          width: parent.width
          text: root.weatherCond || "No weather signal"
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 22
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          text: (root.weatherHum ? "Humidity  " + root.weatherHum : "") + (root.weatherWind ? "\nWind  " + root.weatherWind : "")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 18
        }
      }
    }

    CorePane {
      id: melchior
      width: (parent.width - 32) / 3
      height: parent.height
      coreId: "02"
      title: "MELCHIOR"

      Column {
        parent: melchior.body
        width: parent.width
        spacing: 20
        Meter { label: "CPU"; value: root.cpuUsage; width: parent.width }
        Meter { label: "Memory"; value: root.memUsage; width: parent.width }
        Meter { label: "Disk"; value: root.diskUsage; width: parent.width }
      }
    }

    CorePane {
      id: casper
      width: (parent.width - 32) / 3
      height: parent.height
      coreId: "03"
      title: "CASPER"

      Column {
        parent: casper.body
        width: parent.width
        spacing: 16

        Text {
          width: parent.width
          text: root.trackTitle || "No signal"
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 24
          font.bold: true
          wrapMode: Text.WordWrap
          maximumLineCount: 2
        }
        Text {
          width: parent.width
          text: root.trackArtist || "Casper is idle"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 18
          wrapMode: Text.WordWrap
        }
        Row {
          spacing: 12
          Repeater {
            model: [
              { label: "PREV", action: "prev" },
              { label: root.playing ? "PAUSE" : "PLAY", action: "play" },
              { label: "NEXT", action: "next" }
            ]
            Rectangle {
              required property var modelData
              width: 100
              height: 44
              color: hit.containsMouse ? "#402010" : "#1a1210"
              border.width: 1
              border.color: root.accent
              Text {
                anchors.centerIn: parent
                text: modelData.label
                color: root.paper
                font.family: root.fontFamily
                font.pixelSize: 15
                font.bold: true
              }
              MouseArea {
                id: hit
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mediaAction(modelData.action)
              }
            }
          }
        }
      }
    }
  }
}
