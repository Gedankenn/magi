import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var screen
  required property var host
  property bool opened: false
  property bool hovered: false

  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color accent: Color.accent
  readonly property var borderSpec: Border.flat("#FF6A00", 2)
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
  readonly property int cardWidth: {
    var island = host && host.centerIslandWidth ? host.centerIslandWidth : 0
    return Math.max(Math.round(island), Style.space(560))
  }
  readonly property int cardHeight: Style.space(248)
  readonly property real shownY: {
    var gap = host && host.sideGap ? host.sideGap : Style.gapsOut
    var size = host && host.barSize ? host.barSize : Style.bar.sizeHorizontal
    return gap + size + 2
  }
  readonly property real parkedY: shownY - 18

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
    if (value >= 0.85) return Color.urgent
    if (value >= 0.6) return accent
    return "#A8FF3E"
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
    property string title: ""
    property string subtitle: ""
    default property alias extra: body.data
    color: Qt.rgba(1, 1, 1, 0.03)
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    radius: Math.max(4, Style.cornerRadius)

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(10)
      spacing: Style.space(8)

      Row {
        spacing: Style.space(8)
        Text {
          text: pane.title
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.6
          font.bold: true
        }
        Text {
          text: pane.subtitle
          color: Qt.darker(root.foreground, 1.7)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.2
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Item {
        id: body
        width: parent.width
        height: parent.height - Style.space(22)
      }
    }
  }

  component MeterRow: Row {
    property string label: ""
    property real value: 0
    width: parent ? parent.width : 160
    spacing: Style.space(8)

    Text {
      width: Style.space(32)
      text: label
      color: Qt.darker(root.foreground, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.letterSpacing: 1
      anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
      width: Math.max(40, parent.width - Style.space(78))
      height: 7
      radius: 3
      color: Qt.rgba(1, 1, 1, 0.08)
      anchors.verticalCenter: parent.verticalCenter
      Rectangle {
        width: Math.max(2, parent.width * value)
        height: parent.height
        radius: parent.radius
        color: root.meterColor(value)
      }
    }
    Text {
      width: Style.space(36)
      text: root.pct(value)
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      horizontalAlignment: Text.AlignRight
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  PanelWindow {
    id: panel
    screen: root.screen
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (root.opened && root.host && root.host.pinned) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: card }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened && root.host && root.host.pinned
      onClicked: root.host.toggleDash()
    }

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
      height: root.cardHeight
      radius: host && host.islandRadius !== undefined ? host.islandRadius : 0
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.opened ? root.shownY : root.parkedY
      color: root.background
      borderSpec: root.borderSpec
      Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

      HoverHandler {
        onHoveredChanged: root.hovered = hovered
      }

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.space(10)

        HazardStripe {
          width: parent.width
          height: 12
        }

        Item {
          width: parent.width
          height: headerCol.height

          Column {
            id: headerCol
            spacing: 2
            Text {
              text: "MAGI  //  GEOFRONT"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.letterSpacing: 2.4
              font.bold: true
              font.capitalization: Font.AllUppercase
            }
            Text {
              text: root.host && root.host.pinned ? "PINNED  ·  ESC TO RELEASE" : "THE FATE OF MANKIND"
              color: Qt.darker(root.foreground, 1.6)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1.4
            }
          }

          Column {
            anchors.right: parent.right
            Text {
              anchors.right: parent.right
              text: Qt.formatTime(clock.date, "HH:mm:ss")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              font.bold: true
            }
            Text {
              anchors.right: parent.right
              text: Qt.formatDate(clock.date, "dddd d MMMM yyyy").toUpperCase()
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.letterSpacing: 1
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(12)
          height: parent.height - Style.space(88)

          MagiPane {
            width: (parent.width - Style.space(24)) / 3
            height: parent.height
            title: "BALTHASAR"
            subtitle: "WEATHER"
            Column {
              width: parent.width
              spacing: Style.space(6)
              Row {
                spacing: Style.space(8)
                Text { text: root.weatherEmoji || "…"; font.pixelSize: Style.font.display; color: root.foreground }
                Text {
                  text: root.weatherTemp || "—"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
              Text {
                width: parent.width
                text: (root.weatherCond || "AWAITING MAGI FEED").toUpperCase()
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.Wrap
              }
              Text {
                width: parent.width
                text: [root.weatherPlace, root.weatherHum, root.weatherWind].filter(function(s) { return !!s }).join("  ·  ")
                color: Qt.darker(root.foreground, 1.5)
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.Wrap
              }
            }
          }

          MagiPane {
            width: (parent.width - Style.space(24)) / 3
            height: parent.height
            title: "MELCHIOR"
            subtitle: "SYSTEM"
            Column {
              width: parent.width
              spacing: Style.space(12)
              MeterRow { label: "CPU"; value: root.cpuUsage }
              MeterRow { label: "MEM"; value: root.memUsage }
              MeterRow { label: "DSK"; value: root.diskUsage }
            }
          }

          MagiPane {
            width: (parent.width - Style.space(24)) / 3
            height: parent.height
            title: "CASPER"
            subtitle: "MEDIA"
            Column {
              width: parent.width
              spacing: Style.space(8)
              Text {
                width: parent.width
                text: root.trackTitle || "NO SIGNAL"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
              }
              Text {
                width: parent.width
                text: root.trackArtist || "Casper is idle"
                color: Qt.darker(root.foreground, 1.45)
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }
              Row {
                spacing: Style.space(10)
                Repeater {
                  model: [
                    { glyph: "󰒮", action: "prev" },
                    { glyph: root.playing ? "󰏤" : "󰐊", action: "play" },
                    { glyph: "󰒭", action: "next" }
                  ]
                  Rectangle {
                    required property var modelData
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: 4
                    color: hit.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    Text {
                      anchors.centerIn: parent
                      text: modelData.glyph
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.title
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

      Item {
        anchors.fill: parent
        focus: root.opened && root.host && root.host.pinned
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.host.toggleDash()
            event.accepted = true
          } else if (event.text === "r" || event.text === "R") {
            root.refreshAll()
            event.accepted = true
          } else if (event.key === Qt.Key_Space) {
            root.mediaAction("play")
            event.accepted = true
          }
        }
      }
    }
  }
}
