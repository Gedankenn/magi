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
  readonly property string displayFont: host && host.displayFont ? host.displayFont : "Chakra Petch"

  property string weatherEmoji: ""
  property string weatherTemp: ""
  property string weatherCond: ""
  property string weatherHum: ""
  property string weatherWind: ""
  property string weatherPlace: ""
  property string locationQuery: ""
  property string cityName: ""
  property var dailyForecast: []
  property var hourlySeries: []
  property int seriesMax: 0
  property int seriesMin: 0
  property real cpuUsage: 0
  property real memUsage: 0
  property real diskUsage: 0
  property string cpuTemp: ""
  property string gpuTemp: ""
  property string gpuUsage: ""
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
    var q = String(root.locationQuery || "")
    var locPart = q.length > 0 ? q : ""
    weatherProc.command = ["curl", "-fsS", "-A", "magi-dashboard", "--max-time", "6",
      "https://wttr.in/" + locPart + "?format=%c|%t|%C|%h|%w|%l&m"]
    weatherProc.running = true
    forecastProc.command = ["curl", "-fsS", "-A", "magi-dashboard", "--max-time", "7",
      "https://wttr.in/" + locPart + "?format=j1&m"]
    forecastProc.running = true
  }

  function parseForecast(raw) {
    try {
      var data = JSON.parse(String(raw || ""))
      var area = data.nearest_area && data.nearest_area[0]
      if (area) {
        var nm = area.areaName && area.areaName[0] ? area.areaName[0].value : ""
        var rg = area.region && area.region[0] ? area.region[0].value : ""
        cityName = nm + (rg && rg !== nm ? ", " + rg : "")
        if (!weatherPlace && area.country && area.country[0]) cityName += (cityName ? ", " : "") + area.country[0].value
      }
      var list = []
      var series = []
      var maxT = -999, minT = 999
      var days = data.weather || []
      for (var i = 0; i < days.length; i++) {
        var w = days[i]
        list.push({
          date: String(w.date || ""),
          min: parseInt(w.mintempC) || 0,
          max: parseInt(w.maxtempC) || 0,
          desc: w.hourly && w.hourly[0] && w.hourly[0].weatherDesc ? w.hourly[0].weatherDesc[0].value : ""
        })
        var hours = w.hourly || []
        for (var h = 0; h < hours.length; h++) {
          var t = parseInt(hours[h].time) / 100
          var tempC = parseFloat(hours[h].tempC)
          if (isNaN(tempC)) continue
          series.push({ t: i * 24 + t, temp: tempC })
          if (tempC > maxT) maxT = tempC
          if (tempC < minT) minT = tempC
        }
      }
      dailyForecast = list
      hourlySeries = series
      seriesMax = maxT
      seriesMin = minT
    } catch (e) {
      dailyForecast = []
      hourlySeries = []
    }
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
    cpuTemp = map.tcpu || ""
    gpuTemp = map.tgpu || ""
    gpuUsage = map.gpu || ""
  }

  function meterColor(value) {
    if (value >= 0.85) return blood
    if (value >= 0.6) return accent
    return acid
  }

  function dayLabel(iso) {
    var d = new Date(Date.parse(iso))
    if (isNaN(d.getTime())) return ""
    var today = new Date()
    var dClear = new Date(d.getFullYear(), d.getMonth(), d.getDate())
    var tClear = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    if (dClear.getTime() === tClear.getTime()) return "TODAY"
    return Qt.locale("en_US").dayName(d.getDay(), Locale.ShortFormat).toUpperCase()
  }

  function forecastSpan() {
    var hi = -999, lo = 999
    for (var i = 0; i < dailyForecast.length; i++) {
      if (dailyForecast[i].max > hi) hi = dailyForecast[i].max
      if (dailyForecast[i].min < lo) lo = dailyForecast[i].min
    }
    if (hi === -999) { hi = 30; lo = 0 }
    return Math.max(4, hi - lo)
  }

  function tempBarH(temp) {
    var lo = 999
    for (var i = 0; i < dailyForecast.length; i++) if (dailyForecast[i].min < lo) lo = dailyForecast[i].min
    if (lo === 999) lo = 0
    var span = root.forecastSpan()
    return Math.max(2, Math.round((temp - lo) / span * 60))
  }

  function sTMax() {
    var last = 0
    for (var i = 0; i < hourlySeries.length; i++) if (hourlySeries[i].t > last) last = hourlySeries[i].t
    return last
  }

  function sTMin() {
    if (hourlySeries.length === 0) return 0
    return hourlySeries[0].t
  }

  function spX(t, w) {
    var t0 = root.sTMin(), t1 = root.sTMax()
    var range = Math.max(1, t1 - t0)
    return 8 + (t - t0) / range * (w - 16)
  }

  function spY(temp, h) {
    var lo = Math.min(root.seriesMin, 0), hi = root.seriesMax
    var span = Math.max(1, hi - lo)
    return 10 + (1 - (temp - lo) / span) * (h - 20)
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
    id: forecastProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseForecast(text)
    }
  }

  Process {
    id: statsProc
    command: ["sh", "-c", "echo cpu=$(grep '^cpu ' /proc/stat); echo mem=$(awk '/MemTotal:|MemAvailable:/{print}' /proc/meminfo); echo disk=$(df -P / | awk 'NR==2{print $5}'); echo tcpu=$(sensors 2>/dev/null | awk '/k10temp/{f=1;next} f&&/Tctl:/{gsub(/[^0-9.]/,\"\",$2); print $2; exit}'); echo tgpu=$(sensors 2>/dev/null | awk '/amdgpu-pci-0300/{f=1;next} f&&/edge:/{gsub(/[^0-9.]/,\"\",$2); print $2; exit}'); echo gpu=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null)"]
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
      anchors.leftMargin: 14
      anchors.topMargin: 10
      text: pane.coreId + "   " + pane.title
      color: root.accent
      font.family: root.displayFont
      font.pixelSize: 14
      font.weight: 600
      font.letterSpacing: 2
    }

    Rectangle {
      id: paneRule
      anchors.top: paneHead.bottom
      anchors.topMargin: 8
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 10
      height: 1
      color: "#5A2A10"
    }

    Item {
      id: paneBody
      anchors.top: paneRule.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: 10
      anchors.leftMargin: 14
      anchors.rightMargin: 10
      anchors.bottomMargin: 10
    }
  }

  component Meter: Item {
    property string label: ""
    property real value: 0
    property string text: ""
    property string barColor: ""
    height: 38
    width: parent ? parent.width : 200

    Text {
      text: label
      color: root.muted
      font.family: root.fontFamily
      font.pixelSize: 11
      font.bold: true
    }
    Text {
      anchors.right: parent.right
      text: root.text ? root.text : root.pct(value)
      color: root.paper
      font.family: root.fontFamily
      font.pixelSize: 15
      font.bold: true
    }
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 8
      color: "#2a1510"
      Rectangle {
        width: Math.max(5, parent.width * Math.max(0.02, Math.min(1, value)))
        height: parent.height
        color: text.length > 0 && barColor.length > 0 ? barColor : (barColor.length > 0 ? barColor : root.meterColor(value))
      }
    }
  }

  Item {
    id: topBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 46

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      text: root.host && root.host.pinned ? "PINNED" : (root.weatherPlace || "GEOFRONT").toUpperCase()
      color: root.paper
      font.family: root.displayFont
      font.pixelSize: 15
      font.weight: 600
      font.letterSpacing: 2
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatTime(clock.date, "HH:mm:ss")
      color: root.paper
      font.family: root.displayFont
      font.pixelSize: 30
      font.weight: 600
      font.letterSpacing: 1
    }
  }

  Row {
    id: cores
    anchors.top: topBar.bottom
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    anchors.bottomMargin: 16
    spacing: 12

    CorePane {
      id: balthasar
      width: (parent.width - 24) / 3
      height: parent.height
      coreId: "01"
      title: "BALTHASAR"

      Column {
        parent: balthasar.body
        width: parent.width
        spacing: 10

        Text {
          width: parent.width
          text: (root.cityName || root.weatherPlace || "GEOFRONT").toUpperCase()
          color: root.accent
          font.family: root.displayFont
          font.pixelSize: 15
          font.weight: 600
          font.letterSpacing: 2
          elide: Text.ElideRight
        }

        Text {
          text: (root.weatherTemp || "—") + "   " + (root.weatherEmoji || "")
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 30
          font.bold: true
        }
        Text {
          width: parent.width
          text: root.weatherCond || "No weather signal"
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 13
          wrapMode: Text.WordWrap
        }
        Text {
          width: parent.width
          text: (root.weatherHum ? "Hum  " + root.weatherHum : "") + (root.weatherWind ? "   Wind  " + root.weatherWind : "")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 11
        }

        Rectangle {
          width: parent.width
          height: 1
          color: "#5A2A10"
        }

        Text {
          text: "NEXT DAYS"
          color: root.muted
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 2
        }

        Canvas {
          id: tempChart
          width: parent.width
          height: 96

          onPaint: {
            var ctx = tempChart.getContext("2d")
            var w = tempChart.width
            var h = tempChart.height
            ctx.clearRect(0, 0, w, h)

            var series = root.hourlySeries
            if (!series || series.length < 2) return

            ctx.lineJoin = "round"
            ctx.lineCap = "round"

            ctx.strokeStyle = "#3a2418"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(0, h - 22)
            ctx.lineTo(w, h - 22)
            ctx.stroke()

            for (var d = 0; d < root.dailyForecast.length; d++) {
              var dx = root.spX(d * 24, w)
              ctx.strokeStyle = Qt.rgba(0.35, 0.14, 0.1, 1)
              ctx.lineWidth = 1
              ctx.beginPath()
              ctx.moveTo(dx, 6)
              ctx.lineTo(dx, h - 26)
              ctx.stroke()

              var label = root.dayLabel(root.dailyForecast[d].date)
              ctx.fillStyle = "#9A8B7C"
              ctx.font = "600 10px 'Chakra Petch'"
              ctx.textAlign = "center"
              ctx.fillText(label, dx, 10)
            }

            ctx.strokeStyle = "#FF6A00"
            ctx.lineWidth = 2
            ctx.beginPath()
            for (var i = 0; i < series.length; i++) {
              var px = root.spX(series[i].t, w)
              var py = root.spY(series[i].temp, h)
              if (i === 0) ctx.moveTo(px, py)
              else ctx.lineTo(px, py)
            }
            ctx.stroke()

            var maxIdx = 0, minIdx = 0
            for (var m = 0; m < series.length; m++) {
              if (series[m].temp > series[maxIdx].temp) maxIdx = m
              if (series[m].temp < series[minIdx].temp) minIdx = m
            }

            ctx.fillStyle = "#FF6A00"
            for (var j = 0; j < series.length; j++) {
              ctx.beginPath()
              ctx.arc(root.spX(series[j].t, w), root.spY(series[j].temp, h), 2, 0, Math.PI * 2)
              ctx.fill()
            }

            ctx.fillStyle = "#A8FF3E"
            var mxx = root.spX(series[maxIdx].t, w)
            var mxy = root.spY(series[maxIdx].temp, h)
            ctx.beginPath(); ctx.arc(mxx, mxy, 3, 0, Math.PI * 2); ctx.fill()
            ctx.font = "600 10px 'Chakra Petch'"
            ctx.textAlign = "center"
            ctx.fillText("▲ " + series[maxIdx].temp + "\u00b0C", mxx, Math.max(12, mxy - 6))

            ctx.fillStyle = "#C41E3A"
            var mnx = root.spX(series[minIdx].t, w)
            var mny = root.spY(series[minIdx].temp, h)
            ctx.beginPath(); ctx.arc(mnx, mny, 3, 0, Math.PI * 2); ctx.fill()
            ctx.fillText("▼ " + series[minIdx].temp + "\u00b0C", mnx, Math.min(h - 10, mny + 12))
          }

          Connections {
            target: root
            function onHourlySeriesChanged() { tempChart.requestPaint() }
            function onSeriesMaxChanged() { tempChart.requestPaint() }
            function onSeriesMinChanged() { tempChart.requestPaint() }
            function onDailyForecastChanged() { tempChart.requestPaint() }
          }
        }
      }
    }

    CorePane {
      id: melchior
      width: (parent.width - 24) / 3
      height: parent.height
      coreId: "02"
      title: "MELCHIOR"

      Column {
        parent: melchior.body
        width: parent.width
        spacing: 14
        Meter { label: "CPU"; value: root.cpuUsage; width: parent.width }
        Meter { label: "Memory"; value: root.memUsage; width: parent.width }
        Meter { label: "Disk"; value: root.diskUsage; width: parent.width }
        Meter { label: "Temp"; value: (parseFloat(root.cpuTemp) || 0) / 100; text: root.cpuTemp + "\u00b0C"; barColor: root.accent; width: parent.width }
        Meter { label: "GPU RX5600XT"; value: (parseFloat(root.gpuUsage) || 0) / 100; text: root.gpuUsage + "%  " + root.gpuTemp + "\u00b0C"; barColor: root.acid; width: parent.width }
      }
    }

    CorePane {
      id: casper
      width: (parent.width - 24) / 3
      height: parent.height
      coreId: "03"
      title: "CASPER"

      Column {
        parent: casper.body
        width: parent.width
        spacing: 12

        Text {
          width: parent.width
          visible: root.activePlayer !== null
          text: root.trackTitle || "No signal"
          color: root.paper
          font.family: root.fontFamily
          font.pixelSize: 15
          font.bold: true
          wrapMode: Text.WordWrap
          maximumLineCount: 2
        }
        Text {
          width: parent.width
          visible: root.activePlayer !== null
          text: root.trackArtist || "Casper is idle"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 12
          wrapMode: Text.WordWrap
        }

        Column {
          visible: root.activePlayer === null
          width: parent.width
          spacing: 6

          Text {
            width: parent.width
            text: "AWAITING SIGNAL"
            color: root.accent
            font.family: root.displayFont
            font.pixelSize: 14
            font.weight: 600
            font.letterSpacing: 2.5
            horizontalAlignment: Text.AlignHCenter
          }

          Rectangle {
            id: scanField
            width: parent.width
            height: 18
            color: "#141014"
            clip: true

            Rectangle {
              id: scanBeam
              width: 120
              height: parent.height
              color: Qt.rgba(1, 0.42, 0, 0.16)
              visible: false
            }

            SequentialAnimation {
              running: root.activePlayer === null && scanField.width > 0
              loops: Animation.Infinite
              onStarted: {
                scanBeam.x = -scanBeam.width
                scanBeam.visible = true
              }
              NumberAnimation {
                target: scanBeam
                property: "x"
                from: -120
                to: scanField.width + 20
                duration: 2600
                easing.type: Easing.InOutSine
              }
              PauseAnimation { duration: 900 }
            }
          }

          Text {
            width: parent.width
            text: "-- NO SOURCE ATTACHED --"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 2
            horizontalAlignment: Text.AlignHCenter
          }
        }
        Row {
          spacing: 8
          Repeater {
            model: [
              { label: "PREV", action: "prev" },
              { label: root.playing ? "PAUSE" : "PLAY", action: "play" },
              { label: "NEXT", action: "next" }
            ]
            Rectangle {
              required property var modelData
              width: 60
              height: 30
              color: hit.containsMouse ? "#402010" : "#1a1210"
              border.width: 1
              border.color: root.accent
              Text {
                anchors.centerIn: parent
                text: modelData.label
                color: root.paper
                font.family: root.fontFamily
                font.pixelSize: 11
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
