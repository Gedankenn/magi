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
  readonly property color muted: "#8a7a6e"
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

  width: parent ? parent.width : 1280
  height: parent ? parent.height : 400
  opacity: opened ? 1 : 0
  visible: opacity > 0.02
  Behavior on opacity { NumberAnimation { duration: 160 } }

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

  component MagiPane: Rectangle {
    id: pane
    property string core: ""
    property string title: ""
    property string subtitle: ""
    default property alias extra: body.data
    color: "#141014"
    border.color: Qt.rgba(1, 0.42, 0, 0.28)
    border.width: 1

    Rectangle {
      width: 4
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      color: root.accent
    }

    Column {
      anchors.fill: parent
      anchors.leftMargin: 18
      anchors.rightMargin: 16
      anchors.topMargin: 14
      anchors.bottomMargin: 14
      spacing: 10

      Row {
        spacing: 10
        width: parent.width
        Text {
          text: pane.core
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: 12
          font.letterSpacing: 2
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: pane.title
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 18
          font.letterSpacing: 2.2
          font.bold: true
          font.capitalization: Font.AllUppercase
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: pane.subtitle
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 13
          font.letterSpacing: 1.6
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 0.42, 0, 0.22) }

      Item {
        id: body
        width: parent.width
        height: parent.height - 42
      }
    }
  }

  component MeterRow: Column {
    property string label: ""
    property real value: 0
    width: parent ? parent.width : 200
    spacing: 6

    Row {
      width: parent.width
      Text {
        text: label
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: 14
        font.letterSpacing: 2
        font.bold: true
      }
      Text {
        width: parent.width - 60
        text: root.pct(value)
        color: root.paper
        font.family: root.fontFamily
        font.pixelSize: 16
        font.bold: true
        horizontalAlignment: Text.AlignRight
      }
    }
    Rectangle {
      width: parent.width
      height: 12
      color: "#2a1510"
      Rectangle {
        width: Math.max(4, parent.width * value)
        height: parent.height
        color: root.meterColor(value)
      }
    }
  }

  Column {
    anchors.fill: parent
    anchors.margins: 18
    spacing: 14

    Item {
      width: parent.width
      height: 52

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
          text: root.host && root.host.pinned ? "PINNED  ·  ESC RELEASES" : "SYNCHRONIZED  ·  THE FATE OF MANKIND"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 13
          font.letterSpacing: 1.8
        }
        Text {
          text: (root.weatherPlace || "AWAITING MAGI FEED").toUpperCase()
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 15
          font.letterSpacing: 1.4
        }
      }

      Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        Text {
          anchors.right: parent.right
          text: Qt.formatTime(clock.date, "HH:mm:ss")
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 36
          font.bold: true
        }
        Text {
          anchors.right: parent.right
          text: Qt.formatDate(clock.date, "dddd d MMMM yyyy").toUpperCase()
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 13
          font.letterSpacing: 1.6
        }
      }
    }

    Row {
      width: parent.width
      spacing: 14
      height: parent.height - 80

      MagiPane {
        width: (parent.width - 28) / 3
        height: parent.height
        core: "01"
        title: "BALTHASAR"
        subtitle: "WEATHER"
        Column {
          width: parent.width
          spacing: 10
          Row {
            spacing: 12
            Text {
              text: root.weatherEmoji || "·"
              font.pixelSize: 42
              color: root.paper
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: root.weatherTemp || "—"
              color: root.paper
              font.family: root.fontFamily
              font.pixelSize: 42
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }
          Text {
            width: parent.width
            text: (root.weatherCond || "NO SIGNAL").toUpperCase()
            color: root.paper
            font.family: root.fontFamily
            font.pixelSize: 18
            wrapMode: Text.Wrap
          }
          Text {
            width: parent.width
            text: [root.weatherHum ? ("HUM " + root.weatherHum) : "", root.weatherWind ? ("WIND " + root.weatherWind) : ""].filter(function(s) { return !!s }).join("    ")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: 15
            wrapMode: Text.Wrap
          }
        }
      }

      MagiPane {
        width: (parent.width - 28) / 3
        height: parent.height
        core: "02"
        title: "MELCHIOR"
        subtitle: "SYSTEM"
        Column {
          width: parent.width
          spacing: 18
          MeterRow { label: "CPU"; value: root.cpuUsage }
          MeterRow { label: "MEM"; value: root.memUsage }
          MeterRow { label: "DSK"; value: root.diskUsage }
        }
      }

      MagiPane {
        width: (parent.width - 28) / 3
        height: parent.height
        core: "03"
        title: "CASPER"
        subtitle: "MEDIA"
        Column {
          width: parent.width
          spacing: 12
          Text {
            width: parent.width
            text: root.trackTitle || "NO SIGNAL"
            color: root.paper
            font.family: root.fontFamily
            font.pixelSize: 22
            font.bold: true
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
          }
          Text {
            width: parent.width
            text: root.trackArtist || "Casper is idle"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: 16
            elide: Text.ElideRight
          }
          Row {
            spacing: 10
            Repeater {
              model: [
                { label: "PREV", action: "prev" },
                { label: root.playing ? "PAUSE" : "PLAY", action: "play" },
                { label: "NEXT", action: "next" }
              ]
              Rectangle {
                required property var modelData
                width: 86
                height: 36
                color: hit.containsMouse ? Qt.rgba(1, 0.42, 0, 0.28) : "#1a1210"
                border.width: 1
                border.color: hit.containsMouse ? root.accent : Qt.rgba(1, 0.42, 0, 0.35)
                Text {
                  anchors.centerIn: parent
                  text: modelData.label
                  color: root.paper
                  font.family: root.fontFamily
                  font.pixelSize: 13
                  font.letterSpacing: 1.6
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
}
