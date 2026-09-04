import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "omarchy.clock"
  ipcTarget: "omarchy.clock"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property date today: new Date()
  readonly property color paper: "#F4F0E6"
  readonly property color muted: "#9A8B7C"
  readonly property color accent: "#FF6A00"
  readonly property color blood: "#C41E3A"
  readonly property string displayFont: "Chakra Petch"
  readonly property string bodyFont: bar ? bar.fontFamily : "Nimbus Sans Narrow"

  function open() {
    refresh()
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function refresh() {
    root.today = new Date()
    if (calGrid) calGrid.goToToday()
  }

  function toggleWeekStart() {
    if (!calGrid) return
    calGrid.weekStart = calGrid.weekStart === 1 ? 0 : 1
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.today = clock.date
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    padding: 16
    contentWidth: panel.fittedContentWidth(calColumn.implicitWidth + 8)
    contentHeight: panel.fittedContentHeight(calColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.refresh()
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) calGrid.moveMonth(dx)
        if (dy !== 0) calGrid.moveMonth(dy * 12)
      }
      onTextKey: function(t) {
        if (t === "[" || t === "h") calGrid.moveMonth(-1)
        else if (t === "]" || t === "l") calGrid.moveMonth(1)
        else if (t === "t" || t === "T") root.refresh()
        else if (t === "w" || t === "W") root.toggleWeekStart()
      }

      Column {
        id: calColumn
        width: calGrid.implicitWidth
        spacing: 12

        Text {
          text: "04   SACHIEL"
          color: root.accent
          font.family: root.displayFont
          font.pixelSize: 13
          font.letterSpacing: 2.4
          font.weight: 600
        }

        Text {
          text: Qt.formatDate(root.today, "dddd d MMMM").toUpperCase()
          color: root.paper
          font.family: root.displayFont
          font.pixelSize: 18
          font.letterSpacing: 1.4
          font.weight: 600
        }

        Rectangle { width: parent.width; height: 1; color: "#5A2A10" }

        MagiCalendar {
          id: calGrid
          today: root.today
          paper: root.paper
          muted: root.muted
          accent: root.accent
          blood: root.blood
          displayFont: root.displayFont
          fontFamily: root.bodyFont
          cellSize: 32
        }
      }
    }
  }
}
