import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// EVA-styled clock for the bar. Replaces the stock omarchy.clock label with
// an Evangelion-themed read-out (Orbitron, CAIXA ALTA, technical spacing and
// colors) while reusing the stock plugin's calendar popup so clicking still
// opens the month grid.
//
// Theme: third-impact (EVA). Accent #FF6A00, red #C41E3A, cream #e8dcc8.
BarWidget {
  id: root
  moduleName: "omarchy.clock"

  readonly property string evaFont: "Chakra Petch"
  readonly property string segFont: dsegLoader.status === FontLoader.Ready ? dsegLoader.name : "DSEG7 Classic"
  readonly property color accent: "#FF6A00"
  readonly property color red: "#C41E3A"
  readonly property color cream: "#e8dcc8"

  FontLoader {
    id: dsegLoader
    source: "file://" + Quickshell.env("HOME") + "/.local/share/fonts/dseg/DSEG7Classic-Bold.ttf"
  }

  property date displayDate: clock.date

  // ---- Label text
  readonly property string timeText: Qt.formatTime(displayDate, "HH:mm")
  readonly property string dateText: Qt.formatDate(displayDate, "dd.MM.yy")
  readonly property bool dateOnly: {
    var f = currentFormat()
    return f.indexOf("d") !== -1 && f.indexOf("H") === -1
  }
  readonly property string ghostMask: currentFormat() === "HH:mm:ss" ? "88:88:88" : "88:88"

  // Live format. The bar feeds `format` through the injected settings; a
  // right-click cycle writes the same value back to shell.json, so keeping it
  // here (not in a one-time default) lets the ring walk without a reload.
  function currentFormat() {
    var f = setting("format", "HH:mm")
    return (typeof f === "string" && f.length > 0) ? f : "HH:mm"
  }

  function formatRing() {
    var ring = ["HH:mm", "HH:mm:ss", "HH mm", "dd MMM yyyy"]
    var alt = setting("formatAlt", "")
    if (typeof alt === "string" && alt.length > 0 && ring.indexOf(alt) === -1)
      ring.push(alt)
    return ring
  }

  function cycleFormat() {
    var ring = formatRing()
    var idx = ring.indexOf(currentFormat())
    var next = ring[(idx + 1) % ring.length]

    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    entry.format = next
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  readonly property string shownTime: {
    var f = currentFormat()
    var d = displayDate
    if (f === "HH:mm:ss") return Qt.formatTime(d, "HH:mm:ss")
    if (f === "HH mm") return Qt.formatTime(d, "HH") + ":" + Qt.formatTime(d, "mm")
    if (f === "dd MMM yyyy") return Qt.formatDate(d, "dd MMM yyyy").toUpperCase()
    if (f.indexOf("d") !== -1 && f.indexOf("H") === -1)
      return Qt.formatDate(d, f).toUpperCase()
    try { return Qt.formatTime(d, f) } catch (e) { return Qt.formatTime(d, "HH:mm") }
  }

  function refresh() {
    displayDate = new Date()
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  // ---- Calendar popup (reuse stock panel). Same contract as the stock
  //      widget so the bar's open/close/summon routing keeps working.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function toggleWeekStart() { if (panelLoader.item) panelLoader.item.toggleWeekStart() }

  readonly property real openPanelIndicatorWidth: (root.vertical ? Style.space(10) : labelRow.implicitWidth)
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = root
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: row.implicitWidth + horizontalMargin * 2
  implicitHeight: Math.max(36, row.implicitHeight + verticalPadding * 2)

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  readonly property real horizontalMargin: 10
  readonly property real verticalPadding: 4

  readonly property bool wantsSeconds: currentFormat().indexOf("s") !== -1 || currentFormat().indexOf("S") !== -1

  SystemClock {
    id: clock
    precision: root.wantsSeconds ? SystemClock.Seconds : SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }

  Loader {
    id: panelLoader
    active: true
    source: "file://" + Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.gedankenn.magi/MagiClockPanel.qml"
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "omarchy.clock"
    function refresh(): void { root.broadcast("refresh") }
    function cycleFormat(): void { root.cycleFormat() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  Item {
    id: labelRow
    width: root.vertical ? root.barSize : row.implicitWidth
    height: root.vertical ? row.implicitHeight : row.implicitHeight
    anchors.centerIn: parent

    Row {
      id: row
      spacing: 10
      anchors.centerIn: parent

      MagiSeg {
        visible: !root.dateOnly
        anchors.verticalCenter: parent.verticalCenter
        value: root.shownTime
        ghost: root.ghostMask
        ink: root.accent
        family: root.segFont
        pixelSize: 16
        tracking: 1
        glow: false
      }

      Text {
        visible: root.dateOnly
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.shownTime
        color: root.accent
        font.family: root.evaFont
        font.pixelSize: 15
        font.weight: 600
        font.letterSpacing: 1
      }

      Text {
        id: dateLabel
        visible: !root.vertical && !root.dateOnly
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.dateText
        color: "#F4F0E6"
        font.family: "Nimbus Sans Narrow"
        font.pixelSize: 13
        font.weight: 600
        font.letterSpacing: 0.8
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: if (root.bar) root.bar.showTooltip(root, root.bar.vertical ? root.timeText : root.timeText + " — " + root.dateText)
    onExited: if (root.bar) root.bar.hideTooltip(root)

    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) root.cycleFormat()
      else if (mouse.button === Qt.MiddleButton) { if (root.bar) root.bar.run("omarchy-menu-timezone") }
      else root.togglePanel()
    }
  }
}
