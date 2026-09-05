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

  MagiTheme { id: magi }

  readonly property color paper: magi.paper
  readonly property color muted: magi.muted
  readonly property color accent: magi.nerv
  readonly property color blood: magi.seele
  readonly property color acid: magi.acid
  readonly property color casper: magi.casper
  readonly property color cyan: magi.cyan
  readonly property color pane: magi.pane
  readonly property color dim: magi.dim
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : magi.body
  readonly property string displayFont: host && host.displayFont ? host.displayFont : magi.display
  readonly property string segFont: host && host.segFont ? host.segFont : (dsegLoader.status === FontLoader.Ready ? dsegLoader.name : magi.seg)

  FontLoader {
    id: dsegLoader
    source: "file://" + Quickshell.env("HOME") + "/.local/share/fonts/dseg/DSEG7Classic-Bold.ttf"
  }

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
  property string rainPeakLabel: ""
  property real cpuUsage: 0
  property real memUsage: 0
  property real diskUsage: 0
  property string cpuTemp: ""
  property string gpuTemp: ""
  property string gpuUsage: ""
  property var prevCpu: null
  property real mediaTick: 0
  property var cpuHistory: []
  property var gpuHistory: []
  property var memHistory: []
  property var diskHistory: []
  property var cpuTempHistory: []
  property var gpuTempHistory: []
  readonly property int historyCap: 36

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: pickPlayer()
  readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
  readonly property string trackArt: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
  readonly property bool playing: !!(activePlayer && activePlayer.isPlaying)
  readonly property real mediaLength: activePlayer ? Number(activePlayer.length) || 0 : 0
  readonly property real mediaPosition: {
    mediaTick
    return activePlayer ? Number(activePlayer.position) || 0 : 0
  }
  readonly property real mediaRatio: mediaLength > 0 ? Math.max(0, Math.min(1, mediaPosition / mediaLength)) : 0

  width: parent ? parent.width : 1600
  height: parent ? parent.height : 500
  opacity: opened ? 1 : 0
  visible: opacity > 0.02
  Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

  function weatherUrl(query) {
    var loc = String(query || "")
    var path = loc ? encodeURIComponent(loc) : ""
    return "https://wttr.in/" + path
  }

  function startWeather() {
    var base = root.weatherUrl(root.locationQuery)
    weatherProc.command = ["curl", "-fsS", "-A", "magi-dashboard", "--max-time", "6",
      base + "?format=%c|%t|%C|%h|%w|%l&m"]
    weatherProc.running = true
    forecastProc.command = ["curl", "-fsS", "-A", "magi-dashboard", "--max-time", "7",
      base + "?format=j1&m"]
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
      var limit = Math.min(days.length, 3)
      for (var i = 0; i < limit; i++) {
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
          var hum = parseFloat(hours[h].humidity)
          var rain = parseFloat(hours[h].chanceofrain)
          var mm = parseFloat(hours[h].precipMM)
          series.push({
            t: i * 24 + t,
            temp: tempC,
            hum: isNaN(hum) ? 0 : hum,
            rain: isNaN(rain) ? 0 : rain,
            mm: isNaN(mm) ? 0 : mm
          })
          if (tempC > maxT) maxT = tempC
          if (tempC < minT) minT = tempC
        }
      }
      dailyForecast = list
      hourlySeries = series
      seriesMax = maxT
      seriesMin = minT
      root.rainPeakLabel = root.peakRainLabel(series)
    } catch (e) {
      dailyForecast = []
      hourlySeries = []
      rainPeakLabel = ""
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
    root.cpuHistory = root.pushSample(root.cpuHistory, root.cpuUsage * 100)
    root.gpuHistory = root.pushSample(root.gpuHistory, parseFloat(root.gpuUsage) || 0)
    root.memHistory = root.pushSample(root.memHistory, root.memUsage * 100)
    root.diskHistory = root.pushSample(root.diskHistory, root.diskUsage * 100)
    root.cpuTempHistory = root.pushSample(root.cpuTempHistory, parseFloat(root.cpuTemp) || 0)
    root.gpuTempHistory = root.pushSample(root.gpuTempHistory, parseFloat(root.gpuTemp) || 0)
  }

  function pushSample(list, value) {
    var next = (list && list.length) ? list.slice() : []
    next.push(Math.max(0, Number(value) || 0))
    if (next.length > historyCap) next.shift()
    return next
  }

  readonly property string weatherGlyph: {
    var s = (String(weatherCond || "") + " " + String(weatherEmoji || "")).toLowerCase()
    if (/thunder|storm/.test(s)) return "storm"
    if (/snow|sleet|blizzard|ice/.test(s)) return "snow"
    if (/rain|drizzle|shower/.test(s)) return "rain"
    if (/fog|mist|haze|smoke/.test(s)) return "fog"
    if (/sun|clear|fair/.test(s)) return "sun"
    if (/cloud|overcast/.test(s)) return "cloud"
    return weatherCond ? "cloud" : "rain"
  }

  function cycleDay(d) {
    var start = new Date(d.getFullYear(), 0, 0)
    return Math.max(1, Math.floor((d.getTime() - start.getTime()) / 86400000))
  }

  function wash(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  readonly property string hudTime: Qt.formatTime(clock.date, "HH:mm:ss")
  readonly property string hudDateShort: Qt.formatDate(clock.date, "dd.MM.yy")
  readonly property string hudDateLong: Qt.formatDate(clock.date, "ddd dd MMM yyyy").toUpperCase()
  readonly property string hudCycle: "C" + cycleDay(clock.date)

  readonly property string placeLabel: {
    if (cityName && String(cityName).length) return String(cityName).toUpperCase()
    var p = String(weatherPlace || "").trim()
    if (!p || /^-?\d/.test(p)) return "GEOFRONT"
    return p.toUpperCase()
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

  function nowMark() {
    var now = clock.date
    var hour = now.getHours() + now.getMinutes() / 60 + now.getSeconds() / 3600
    var days = dailyForecast || []
    if (!days.length) return hour
    var bits = String(days[0].date || "").split("-")
    if (bits.length < 3) return hour
    var start = new Date(parseInt(bits[0], 10), parseInt(bits[1], 10) - 1, parseInt(bits[2], 10))
    if (isNaN(start.getTime())) return hour
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var dayDiff = Math.round((today.getTime() - start.getTime()) / 86400000)
    return dayDiff * 24 + hour
  }

  readonly property real nowCursor: {
    clock.date
    dailyForecast
    return root.nowMark()
  }

  readonly property int hourAxis: 14

  function hourLabel(t) {
    var hr = Math.round(t) % 24
    if (hr < 0) hr += 24
    return (hr < 10 ? "0" : "") + hr
  }

  function drawNowLine(ctx, w, h) {
    var tNow = root.nowMark()
    var t0 = root.sTMin()
    var t1 = root.sTMax()
    if (!(t1 > t0) || tNow < t0 || tNow > t1) return
    var x = root.spX(tNow, w)
    ctx.save()
    ctx.strokeStyle = "#9B6DFF"
    ctx.lineWidth = 1.2
    ctx.setLineDash([3, 3])
    ctx.beginPath()
    ctx.moveTo(x, 4)
    ctx.lineTo(x, h - root.hourAxis)
    ctx.stroke()
    ctx.restore()
  }

  function drawHourAxis(ctx, w, h) {
    var t0 = root.sTMin()
    var t1 = root.sTMax()
    if (!(t1 > t0)) return
    var axisY = h - root.hourAxis
    ctx.save()
    ctx.strokeStyle = "rgba(122,255,255,0.18)"
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(0, axisY)
    ctx.lineTo(w, axisY)
    ctx.stroke()
    ctx.font = "600 9px 'Chakra Petch'"
    ctx.textAlign = "center"
    ctx.textBaseline = "top"
    var start = Math.ceil(t0 / 6) * 6
    for (var t = start; t <= t1 + 0.05; t += 6) {
      var x = root.spX(t, w)
      ctx.strokeStyle = "rgba(122,255,255,0.22)"
      ctx.beginPath()
      ctx.moveTo(x, axisY)
      ctx.lineTo(x, axisY - 3)
      ctx.stroke()
      ctx.fillStyle = "#B7A99A"
      ctx.fillText(root.hourLabel(t), x, axisY + 2)
    }
    ctx.restore()
  }

  function spY(temp, h) {
    var lo = Math.min(root.seriesMin, 0), hi = root.seriesMax
    var span = Math.max(1, hi - lo)
    var top = 14
    var bot = root.hourAxis + 2
    return top + (1 - (temp - lo) / span) * (h - top - bot)
  }

  function peakRainLabel(series) {
    var list = series || []
    if (!list.length) return ""
    var idx = 0
    for (var i = 1; i < list.length; i++) {
      if ((list[i].mm || 0) > (list[idx].mm || 0)) idx = i
      else if ((list[i].mm || 0) === (list[idx].mm || 0) && (list[i].rain || 0) > (list[idx].rain || 0)) idx = i
    }
    var mm = list[idx].mm || 0
    var rain = Math.round(list[idx].rain || 0)
    if (mm <= 0 && rain <= 0) return ""
    if (mm <= 0) return rain + "%"
    return mm.toFixed(mm >= 10 ? 0 : 1) + "mm  |  " + rain + "%"
  }

  function pct(value) {
    return Math.round((value || 0) * 100) + "%"
  }

  function fmtClock(sec) {
    var s = Math.max(0, Math.floor(sec))
    var m = Math.floor(s / 60)
    var r = s % 60
    return m + ":" + (r < 10 ? "0" : "") + r
  }

  function mediaAction(action) {
    if (!activePlayer) return
    if (action === "play") activePlayer.togglePlaying()
    else if (action === "next") activePlayer.next()
    else activePlayer.previous()
  }

  function seekMedia(ratio) {
    if (!activePlayer || mediaLength <= 0) return
    try { activePlayer.position = mediaLength * Math.max(0, Math.min(1, ratio)) } catch (e) {}
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
    interval: root.opened ? 2000 : 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  Timer {
    interval: 500
    running: root.opened && root.playing
    repeat: true
    onTriggered: root.mediaTick++
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  component CorePane: Rectangle {
    id: pane
    property string coreId: "00"
    property string title: ""
    property string iconKind: ""
    property color accentColor: root.accent
    property color iconColor: root.acid
    property color paneFill: "#161218"
    property bool violet: false
    property alias body: paneBody
    color: pane.paneFill
    border.width: 1
    border.color: root.wash(pane.accentColor, 0.32)

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 52
      gradient: Gradient {
        GradientStop { position: 0.0; color: root.wash(pane.accentColor, 0.10) }
        GradientStop { position: 1.0; color: "transparent" }
      }
    }

    Rectangle {
      width: 4
      anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
      color: pane.accentColor
    }
    Rectangle {
      width: 1
      x: 4
      anchors { top: parent.top; bottom: parent.bottom }
      color: root.wash(pane.accentColor, 0.4)
    }

    Item {
      id: paneHead
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 16
      anchors.rightMargin: 10
      anchors.topMargin: 10
      height: 18

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: pane.coreId + "   " + pane.title
        color: pane.accentColor
        font.family: root.displayFont
        font.pixelSize: 13
        font.weight: 600
        font.letterSpacing: 2.2
      }

      MagiIcon {
        visible: pane.iconKind !== ""
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        kind: pane.iconKind
        stroke: pane.iconColor
        accent: pane.violet ? root.casper : root.cyan
        width: 20
        height: 20
      }
    }

    Rectangle {
      id: paneRule
      anchors.top: paneHead.bottom
      anchors.topMargin: 8
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.right: parent.right
      anchors.rightMargin: 10
      height: 1
      color: root.wash(pane.accentColor, 0.28)
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

  Item {
    id: topBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 56

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      text: root.host && root.host.pinned ? "PINNED" : root.placeLabel
      color: root.host && root.host.pinned ? root.acid : root.paper
      font.family: root.displayFont
      font.pixelSize: 13
      font.weight: 600
      font.letterSpacing: 2.4
    }

    Column {
      anchors.right: parent.right
      anchors.rightMargin: 18
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      MagiSeg {
        anchors.right: parent.right
        value: root.hudTime
        ghost: "88:88:88"
        ink: root.accent
        family: root.segFont
        pixelSize: 28
        tracking: 2
        glow: true
      }

      Row {
        anchors.right: parent.right
        spacing: 8
        Text {
          text: root.hudDateShort
          color: root.accent
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 1.4
          font.weight: 600
        }
        Text { text: "·"; color: root.dim; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: root.hudDateLong
          color: root.muted
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 1.4
          font.weight: 600
        }
        Text { text: "·"; color: root.dim; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Text {
          text: root.hudCycle
          color: root.acid
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 1.4
          font.weight: 600
        }
      }
    }
  }

  Row {
    id: cores
    anchors.top: topBar.bottom
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    anchors.bottomMargin: 14
    spacing: 10

    CorePane {
      id: balthasar
      width: (parent.width - 30) / 4
      height: parent.height
      coreId: "01"
      title: "BALTHASAR"
      iconKind: "balthasar"
      accentColor: root.cyan
      iconColor: root.cyan
      paneFill: magi.paneCool

      Column {
        parent: balthasar.body
        width: parent.width
        spacing: 8

        Row {
          width: parent.width
          spacing: 12

          MagiIcon {
            width: 42
            height: 42
            kind: root.weatherGlyph
            stroke: root.acid
            accent: root.cyan
          }

          Column {
            width: parent.width - 54
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Text {
              text: root.weatherTemp || "—"
              color: root.acid
              font.family: root.displayFont
              font.pixelSize: 34
              font.weight: Font.Bold
            }
            Text {
              width: parent.width
              text: (root.weatherCond || "NO WEATHER SIGNAL").toUpperCase()
              color: root.muted
              font.family: root.displayFont
              font.pixelSize: 11
              font.letterSpacing: 1.8
              font.weight: 600
              elide: Text.ElideRight
            }
          }
        }

        Text {
          width: parent.width
          text: "WEATHER  //  " + root.placeLabel
          color: root.paper
          font.family: root.displayFont
          font.pixelSize: 12
          font.letterSpacing: 1.2
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: (root.weatherHum ? "HUM  " + root.weatherHum : "") + (root.weatherWind ? "   ·   WIND  " + root.weatherWind : "")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: 11
        }

        Rectangle { width: parent.width; height: 1; color: root.wash(root.cyan, 0.22) }

        Text {
          text: "NEXT DAYS"
          color: root.muted
          font.family: root.displayFont
          font.pixelSize: 10
          font.letterSpacing: 2
        }

        Canvas {
          id: tempChart
          width: parent.width
          height: 80
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()

          onPaint: {
            var ctx = tempChart.getContext("2d")
            var w = tempChart.width
            var h = tempChart.height
            ctx.clearRect(0, 0, w, h)

            var series = root.hourlySeries
            if (!series || series.length < 2) return

            var axisY = h - root.hourAxis
            ctx.lineJoin = "round"
            ctx.lineCap = "round"

            for (var d = 0; d < root.dailyForecast.length; d++) {
              var dx = root.spX(d * 24, w)
              ctx.strokeStyle = "rgba(122,255,255,0.12)"
              ctx.lineWidth = 1
              ctx.beginPath()
              ctx.moveTo(dx, 6)
              ctx.lineTo(dx, axisY)
              ctx.stroke()
              ctx.fillStyle = "#B7A99A"
              ctx.font = "600 10px 'Chakra Petch'"
              ctx.textAlign = "center"
              ctx.fillText(root.dayLabel(root.dailyForecast[d].date), dx, 10)
            }

            ctx.strokeStyle = "#7AFFFF"
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

            ctx.fillStyle = "#7AFFFF"
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
            ctx.fillText("▼ " + series[minIdx].temp + "\u00b0C", mnx, Math.min(axisY - 2, mny + 12))

            root.drawHourAxis(ctx, w, h)
            root.drawNowLine(ctx, w, h)
          }

          Connections {
            target: root
            function onHourlySeriesChanged() { tempChart.requestPaint() }
            function onSeriesMaxChanged() { tempChart.requestPaint() }
            function onSeriesMinChanged() { tempChart.requestPaint() }
            function onDailyForecastChanged() { tempChart.requestPaint() }
            function onNowCursorChanged() { tempChart.requestPaint() }
          }
        }

        Item {
          width: parent.width
          height: 12
          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "RAIN  //  HUM"
            color: root.muted
            font.family: root.displayFont
            font.pixelSize: 10
            font.letterSpacing: 2
          }
          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.rainPeakLabel !== ""
            text: root.rainPeakLabel
            color: root.acid
            font.family: root.displayFont
            font.pixelSize: 10
            font.letterSpacing: 1.2
            font.weight: 600
          }
        }

        Canvas {
          id: rainChart
          width: parent.width
          height: 88
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()

          onPaint: {
            var ctx = rainChart.getContext("2d")
            var w = rainChart.width
            var h = rainChart.height
            ctx.clearRect(0, 0, w, h)
            var series = root.hourlySeries
            if (!series || series.length < 2 || w < 8 || h < 8) return

            var axisY = h - root.hourAxis
            var plotH = axisY - 6
            ctx.lineJoin = "round"
            ctx.lineCap = "round"

            var maxMm = 0.4
            var i
            for (i = 0; i < series.length; i++) {
              if ((series[i].mm || 0) > maxMm) maxMm = series[i].mm
            }
            maxMm = maxMm * 1.2

            for (var d = 0; d < root.dailyForecast.length; d++) {
              var dx = root.spX(d * 24, w)
              ctx.strokeStyle = "rgba(122,255,255,0.12)"
              ctx.beginPath()
              ctx.moveTo(dx, 4)
              ctx.lineTo(dx, axisY)
              ctx.stroke()
            }

            var n = series.length
            var slot = (w - 16) / Math.max(1, n)
            var barW = Math.max(2, slot * 0.58)
            var peakIdx = 0
            for (i = 1; i < n; i++) {
              if ((series[i].mm || 0) > (series[peakIdx].mm || 0)) peakIdx = i
            }

            for (i = 0; i < n; i++) {
              var cx = root.spX(series[i].t, w)
              var rain = Math.max(0, Math.min(100, series[i].rain || 0))
              var mm = Math.max(0, series[i].mm || 0)
              var chanceH = (rain / 100) * plotH * 0.55
              var mmH = (mm / maxMm) * plotH
              if (chanceH > 1) {
                ctx.fillStyle = "rgba(122,255,255,0.14)"
                ctx.fillRect(cx - barW / 2, axisY - chanceH, barW, chanceH)
              }
              if (mmH > 1) {
                ctx.fillStyle = i === peakIdx ? "#A8FF3E" : "rgba(122,255,255,0.72)"
                ctx.fillRect(cx - barW / 2, axisY - mmH, barW, mmH)
              }
            }

            ctx.strokeStyle = "#A8FF3E"
            ctx.lineWidth = 1.7
            ctx.beginPath()
            for (i = 0; i < n; i++) {
              var hx = root.spX(series[i].t, w)
              var hy = 6 + (1 - Math.max(0, Math.min(100, series[i].hum || 0)) / 100) * plotH
              if (i === 0) ctx.moveTo(hx, hy)
              else ctx.lineTo(hx, hy)
            }
            ctx.stroke()

            root.drawHourAxis(ctx, w, h)
            root.drawNowLine(ctx, w, h)
          }

          Connections {
            target: root
            function onHourlySeriesChanged() { rainChart.requestPaint() }
            function onDailyForecastChanged() { rainChart.requestPaint() }
            function onNowCursorChanged() { rainChart.requestPaint() }
          }
        }
      }
    }

    CorePane {
      id: sachiel
      width: (parent.width - 30) / 4
      height: parent.height
      coreId: "04"
      title: "SACHIEL"
      iconKind: "sachiel"

      MagiCalendar {
        parent: sachiel.body
        anchors.horizontalCenter: parent.horizontalCenter
        today: clock.date
        paper: root.paper
        muted: root.muted
        accent: root.accent
        blood: root.blood
        displayFont: root.displayFont
        fontFamily: root.fontFamily
        cellSize: Math.floor(Math.min(30, (sachiel.body.width - 4) / 7))
      }
    }

    CorePane {
      id: melchior
      width: (parent.width - 30) / 4
      height: parent.height
      coreId: "02"
      title: "MELCHIOR"
      iconKind: "melchior"

      Item {
        parent: melchior.body
        anchors.fill: parent

        MagiSpark {
          id: loadSpark
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: Math.max(88, Math.floor((parent.height - 16) / 3))
          seriesA: root.cpuHistory
          seriesB: root.gpuHistory
          colorA: root.accent
          colorB: root.acid
          minValue: 0
          maxValue: 100
          labelA: "CPU"
          labelB: "GPU"
          valueA: root.pct(root.cpuUsage)
          valueB: (root.gpuUsage || "0") + "%"
          scaleLow: "0%"
          scaleHigh: "100%"
          displayFont: root.displayFont
          bodyFont: root.fontFamily
        }
        MagiSpark {
          id: storeSpark
          anchors.top: loadSpark.bottom
          anchors.topMargin: 8
          anchors.left: parent.left
          anchors.right: parent.right
          height: loadSpark.height
          seriesA: root.memHistory
          seriesB: root.diskHistory
          colorA: root.accent
          colorB: root.acid
          minValue: 0
          maxValue: 100
          labelA: "MEM"
          labelB: "DISK"
          valueA: root.pct(root.memUsage)
          valueB: root.pct(root.diskUsage)
          scaleLow: "0%"
          scaleHigh: "100%"
          displayFont: root.displayFont
          bodyFont: root.fontFamily
        }
        MagiSpark {
          anchors.top: storeSpark.bottom
          anchors.topMargin: 8
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          seriesA: root.cpuTempHistory
          seriesB: root.gpuTempHistory
          colorA: root.accent
          colorB: root.acid
          minValue: 30
          maxValue: 95
          labelA: "CPU"
          labelB: "GPU"
          valueA: (root.cpuTemp || "—") + "\u00b0C"
          valueB: (root.gpuTemp || "—") + "\u00b0C"
          scaleLow: "30\u00b0C"
          scaleHigh: "95\u00b0C"
          displayFont: root.displayFont
          bodyFont: root.fontFamily
        }
      }
    }

    CorePane {
      id: casper
      width: (parent.width - 30) / 4
      height: parent.height
      coreId: "03"
      title: "CASPER"
      iconKind: "casper"
      accentColor: root.casper
      iconColor: root.casper
      paneFill: magi.paneViolet
      violet: true

      Column {
        parent: casper.body
        width: parent.width
        spacing: 10

        Row {
          visible: root.activePlayer !== null
          width: parent.width
          spacing: 10

          Rectangle {
            width: 72
            height: 72
            color: "#14101c"
            border.width: 1
            border.color: root.casper
            clip: true

            Image {
              anchors.fill: parent
              anchors.margins: 1
              source: root.trackArt
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              visible: root.trackArt !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: root.trackArt === ""
              text: "♪"
              color: root.casper
              font.family: root.displayFont
              font.pixelSize: 28
            }
          }

          Column {
            width: parent.width - 82
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
              width: parent.width
              text: root.trackTitle || "No signal"
              color: root.paper
              font.family: root.fontFamily
              font.pixelSize: 14
              font.bold: true
              wrapMode: Text.WordWrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: root.trackArtist || "Casper is idle"
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: 12
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              visible: root.trackAlbum !== ""
              text: root.trackAlbum
              color: Qt.rgba(0.96, 0.94, 0.9, 0.45)
              font.family: root.fontFamily
              font.pixelSize: 11
              elide: Text.ElideRight
            }
          }
        }

        Column {
          visible: root.activePlayer === null
          width: parent.width
          spacing: 8

          Text {
            width: parent.width
            text: "AWAITING SIGNAL"
            color: root.casper
            font.family: root.displayFont
            font.pixelSize: 13
            font.weight: 600
            font.letterSpacing: 2.5
            horizontalAlignment: Text.AlignHCenter
          }

          Rectangle {
            id: scanField
            width: parent.width
            height: 18
            color: "#14101c"
            clip: true

            Rectangle {
              id: scanBeam
              width: 120
              height: parent.height
              color: Qt.rgba(0.61, 0.43, 1, 0.18)
            }

            SequentialAnimation {
              running: root.activePlayer === null && root.opened && scanField.width > 0
              loops: Animation.Infinite
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

        Item {
          visible: root.activePlayer !== null
          width: parent.width
          height: 28

          Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: root.fmtClock(root.mediaPosition)
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: 10
          }
          Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: root.fmtClock(root.mediaLength)
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: 10
          }

          Rectangle {
            id: seekTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 8
            color: "#1a1424"

            Rectangle {
              width: Math.max(2, parent.width * root.mediaRatio)
              height: parent.height
              color: root.casper
              Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                if (seekTrack.width > 0) root.seekMedia(mouse.x / seekTrack.width)
              }
            }
          }
        }

        MagiVisualizer {
          visible: root.opened && root.activePlayer !== null
          width: parent.width
          height: 46
          barCount: 16
          barWidth: 4
          gap: 2
          fill: root.casper
          hot: root.acid
          levels: root.host && root.host.cavaLevels ? root.host.cavaLevels : []
          peak: root.host && root.host.audioPeak ? root.host.audioPeak : 0
          playing: root.playing
          cavaActive: !!(root.host && root.host.cavaActive)
        }

        Row {
          spacing: 8
          width: parent.width
          Repeater {
            model: [
              { label: "PREV", action: "prev", primary: false },
              { label: root.playing ? "PAUSE" : "PLAY", action: "play", primary: true },
              { label: "NEXT", action: "next", primary: false }
            ]
            MagiBtn {
              required property var modelData
              width: (parent.width - 16) / 3
              height: 30
              label: modelData.label
              accent: root.casper
              paper: root.paper
              displayFont: root.displayFont
              primary: modelData.primary
              onClicked: root.mediaAction(modelData.action)
            }
          }
        }
      }
    }
  }
}
