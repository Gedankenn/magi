import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property var pluginEntry: readPluginEntry()
  readonly property bool autoHideBar: pluginEntry.autoHideBar !== false
  readonly property bool topEdge: pluginEntry.top !== false
  readonly property bool leftEdge: pluginEntry.left !== false
  readonly property bool rightEdge: pluginEntry.right !== false
  readonly property int dashDelay: Math.max(80, parseInt(pluginEntry.dashDelay, 10) || 280)
  readonly property int hideDelay: Math.max(80, parseInt(pluginEntry.hideDelay, 10) || 420)
  readonly property int sensorSize: Math.max(2, parseInt(pluginEntry.sensorSize, 10) || 4)

  property bool pinned: false
  property bool dashOpen: false
  property bool sessionOpen: false
  property bool utilOpen: false
  property bool barWanted: false
  property int topCount: 0
  property int leftCount: 0
  property int rightCount: 0
  readonly property bool topHot: topCount > 0
  readonly property bool leftHot: leftCount > 0
  readonly property bool rightHot: rightCount > 0

  readonly property var bar: shell && shell.bar ? shell.bar : null
  readonly property bool barBusy: !!(bar && (bar.barHovered || bar.activePopout))

  function readPluginEntry() {
    var cfg = shell && shell.shellConfig ? shell.shellConfig : null
    var list = cfg && cfg.plugins ? cfg.plugins : []
    if (!Array.isArray(list)) return ({})
    for (var i = 0; i < list.length; i++) {
      if (list[i] && list[i].id === "io.github.gedankenn.magi") return list[i]
    }
    return ({})
  }

  function setBarHidden(hidden) {
    if (!autoHideBar || !bar) return
    if (bar.barHidden === hidden) return
    bar.barHidden = hidden
  }

  function revealBar() {
    barWanted = true
    hideBarTimer.stop()
    setBarHidden(false)
  }

  function requestHideBar() {
    if (pinned || dashOpen || barBusy || topHot) return
    hideBarTimer.restart()
  }

  function openDash() {
    if (!topEdge) return
    dashOpen = true
    revealBar()
    dashDelayTimer.stop()
  }

  function closeDash() {
    if (pinned) return
    dashOpen = false
    requestHideBar()
  }

  function toggleDash() {
    pinned = !pinned
    if (pinned) openDash()
    else {
      dashOpen = false
      requestHideBar()
    }
  }

  function openSession() {
    if (!leftEdge) return
    sessionOpen = true
    utilOpen = false
  }

  function openUtils() {
    if (!rightEdge) return
    utilOpen = true
    sessionOpen = false
  }

  function closeSides() {
    sessionOpen = false
    utilOpen = false
  }

  function bump(edge, entered) {
    var delta = entered ? 1 : -1
    if (edge === "top") {
      topCount = Math.max(0, topCount + delta)
      if (topHot) {
        revealBar()
        if (!dashOpen && !pinned) dashDelayTimer.restart()
      } else {
        dashDelayTimer.stop()
        if (!pinned) {
          dashCloseTimer.restart()
          requestHideBar()
        }
      }
    } else if (edge === "left") {
      leftCount = Math.max(0, leftCount + delta)
      if (leftHot) leftDelayTimer.restart()
      else {
        leftDelayTimer.stop()
        sessionCloseTimer.restart()
      }
    } else if (edge === "right") {
      rightCount = Math.max(0, rightCount + delta)
      if (rightHot) rightDelayTimer.restart()
      else {
        rightDelayTimer.stop()
        utilCloseTimer.restart()
      }
    }
  }

  Timer {
    id: dashDelayTimer
    interval: root.dashDelay
    onTriggered: if (root.topHot) root.openDash()
  }
  Timer {
    id: dashCloseTimer
    interval: 480
    onTriggered: if (!root.topHot && !root.pinned) root.closeDash()
  }
  Timer {
    id: hideBarTimer
    interval: root.hideDelay
    onTriggered: {
      if (root.pinned || root.dashOpen || root.barBusy || root.topHot) return
      root.barWanted = false
      root.setBarHidden(true)
    }
  }
  Timer {
    id: leftDelayTimer
    interval: 140
    onTriggered: if (root.leftHot) root.openSession()
  }
  Timer {
    id: sessionCloseTimer
    interval: 160
    onTriggered: if (!root.leftHot) root.sessionOpen = false
  }
  Timer {
    id: rightDelayTimer
    interval: 140
    onTriggered: if (root.rightHot) root.openUtils()
  }
  Timer {
    id: utilCloseTimer
    interval: 160
    onTriggered: if (!root.rightHot) root.utilOpen = false
  }

  // Re-assert hide if the stock bar probe flips the flag back.
  Timer {
    interval: 300
    running: root.autoHideBar && !root.barWanted && !root.pinned
    repeat: true
    onTriggered: {
      if (!root.barBusy && !root.topHot) root.setBarHidden(true)
    }
  }

  Connections {
    target: root.bar
    enabled: root.bar !== null
    function onBarHoveredChanged() { root.bump("top", root.bar && root.bar.barHovered) }
  }

  Component.onCompleted: {
    if (autoHideBar) Qt.callLater(function() { if (!barWanted) setBarHidden(true) })
  }
  Component.onDestruction: {
    if (autoHideBar && bar) bar.barHidden = false
  }

  IpcHandler {
    target: "io.github.gedankenn.magi"
    function toggle(): void { root.toggleDash() }
    function open(): void { root.pinned = true; root.openDash() }
    function close(): void { root.pinned = false; root.dashOpen = false; root.closeSides(); root.requestHideBar() }
    function show(): void { root.pinned = true; root.openDash() }
    function hide(): void { root.pinned = false; root.dashOpen = false; root.requestHideBar() }
  }

  Variants {
    model: Quickshell.screens
    delegate: Component {
      EdgeSeat {
        required property var modelData
        screen: modelData
        host: root
      }
    }
  }

  component EdgeSeat: Item {
    id: seat
    required property var screen
    required property var host

    Dashboard {
      id: dash
      screen: seat.screen
      host: seat.host
      opened: seat.host.dashOpen
    }

    SessionDrawer {
      id: session
      screen: seat.screen
      host: seat.host
      opened: seat.host.sessionOpen
    }

    UtilitiesDrawer {
      id: utils
      screen: seat.screen
      host: seat.host
      opened: seat.host.utilOpen
    }

    // Top hover strip + MAGI peek line
    PanelWindow {
      visible: seat.host.topEdge
      screen: seat.screen
      anchors { top: true; left: true; right: true }
      implicitHeight: Math.max(seat.host.sensorSize, seat.host.bar && seat.host.bar.barHidden ? 3 : seat.host.sensorSize)
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "magi-edge-top"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: Color.accent
        opacity: (seat.host.bar && seat.host.bar.barHidden && !seat.host.dashOpen) ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
      }

      HoverHandler {
        onHoveredChanged: seat.host.bump("top", hovered)
      }
    }

    PanelWindow {
      visible: seat.host.leftEdge
      screen: seat.screen
      anchors { top: true; bottom: true; left: true }
      implicitWidth: seat.host.sensorSize
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "magi-edge-left"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: Color.accent
        opacity: seat.host.sessionOpen ? 0 : 0.55
      }

      HoverHandler {
        onHoveredChanged: seat.host.bump("left", hovered)
      }
    }

    PanelWindow {
      visible: seat.host.rightEdge
      screen: seat.screen
      anchors { top: true; bottom: true; right: true }
      implicitWidth: seat.host.sensorSize
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "magi-edge-right"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: Color.accent
        opacity: seat.host.utilOpen ? 0 : 0.55
      }

      HoverHandler {
        onHoveredChanged: seat.host.bump("right", hovered)
      }
    }

    Connections {
      target: dash
      function onHoveredChanged() { seat.host.bump("top", dash.hovered) }
    }
    Connections {
      target: session
      function onHoveredChanged() { seat.host.bump("left", session.hovered) }
    }
    Connections {
      target: utils
      function onHoveredChanged() { seat.host.bump("right", utils.hovered) }
    }
  }
}
