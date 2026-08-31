import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "MagiBarModel.js" as Model

Item {
  id: root

  property string omarchyPath: ""
  property var barWidgetRegistry: null
  property var barConfig: ({})
  property var shell: null
  property var manifest: null
  property var pluginRegistry: null

  property string position: "top"
  readonly property bool vertical: false
  readonly property int barSize: Style.bar.sizeHorizontal + Style.space(14)
  readonly property bool revealed: true
  readonly property bool barHidden: false
  property int barHoverCount: 0
  readonly property bool barHovered: barHoverCount > 0
  property var activePopout: null
  property bool centerHoverRevealSuppressed: false
  readonly property bool centerSectionRevealHeld: revealed
  property bool foregroundAnimationEnabled: true
  property var moduleSlots: []
  property var tooltipTarget: null
  property string tooltipText: ""
  property bool tooltipShown: false

  property color foreground: Color.bar.text
  property color barForeground: foreground
  property color background: Color.menu.background
  property color urgent: Color.bar.active
  property string fontFamily: Style.font.family

  property bool pinned: false
  property bool dashOpen: false
  property bool sessionOpen: false
  property bool utilOpen: false
  property int topCount: 0
  property int leftCount: 0
  property int rightCount: 0
  readonly property bool topHot: topCount > 0
  readonly property bool leftHot: leftCount > 0
  readonly property bool rightHot: rightCount > 0
  readonly property bool barBusy: barHovered || !!activePopout

  property var layoutConfig: ({ left: [], center: [], right: [] })
  property int barConfigSerial: 0
  readonly property int sensorSize: 4
  readonly property int dashDelay: 280
  readonly property int hideDelay: 420
  readonly property int sideGap: Style.gapsOut

  function layoutEntries(region) {
    var serial = barConfigSerial
    var entries = layoutConfig ? layoutConfig[region] : null
    return Array.isArray(entries) ? entries : []
  }

  function applyBarConfig() {
    var config = Util.isPlainObject(barConfig) ? barConfig : {}
    position = Model.normalizePosition(config.position)
    layoutConfig = Util.normalizeLayout(config.layout)
    barConfigSerial++
  }

  onBarConfigChanged: applyBarConfig()
  Component.onCompleted: applyBarConfig()

  function entryId(entry) { return Model.entryId(entry) }
  function entrySettings(entry) { return Model.entrySettings(entry) }
  function canonicalWidgetId(name) { return Util.canonicalWidgetId(name) }

  function registerModuleSlot(slot) {
    if (!slot || moduleSlots.indexOf(slot) !== -1) return
    moduleSlots = moduleSlots.concat([slot])
  }
  function unregisterModuleSlot(slot) {
    moduleSlots = moduleSlots.filter(function(item) { return item !== slot })
  }

  function requestPopout(owner) {
    if (activePopout === owner) return
    if (activePopout) {
      if ("closeForPopoutSwitch" in activePopout) activePopout.closeForPopoutSwitch()
      else if ("close" in activePopout) activePopout.close()
    }
    activePopout = owner
  }

  function releasePopout(owner) {
    if (activePopout === owner) activePopout = null
  }

  function moduleWidgets(pluginId) {
    var id = String(pluginId || "")
    var items = []
    for (var i = 0; i < moduleSlots.length; i++) {
      var slot = moduleSlots[i]
      if (slot && slot.activeItem && slot.moduleName === id) items.push(slot.activeItem)
    }
    return items
  }

  function slotWindow(slot) {
    try { return slot.QsWindow.window } catch (e) { return null }
  }

  function slotScreenName(slot) {
    var window = slotWindow(slot)
    return window && window.screen ? String(window.screen.name || "") : ""
  }

  function focusedScreenName() {
    var monitor = Hyprland.focusedMonitor
    return monitor ? String(monitor.name || "") : ""
  }

  function findPanelWidget(pluginId) {
    var id = String(pluginId || "")
    if (!id) return null
    var candidates = []
    for (var i = 0; i < moduleSlots.length; i++) {
      var slot = moduleSlots[i]
      if (!slot || !slot.activeItem || slot.moduleName !== id) continue
      var item = slot.activeItem
      if (typeof item.open !== "function" || typeof item.close !== "function" || item.opened === undefined) continue
      candidates.push({ slot: slot, activeItem: item, screenName: slotScreenName(slot), opened: item.opened === true })
    }
    var chosen = Model.pickPanelSlot(candidates, focusedScreenName())
    return chosen ? chosen.activeItem : null
  }

  function summonBarWidget(pluginId) {
    var item = findPanelWidget(pluginId)
    if (!item || typeof item.open !== "function") return false
    item.open()
    return true
  }

  function hideBarWidget(pluginId) {
    var item = findPanelWidget(pluginId)
    if (!item || typeof item.close !== "function") return false
    item.close()
    return true
  }

  function isBarWidgetOpen(pluginId) {
    var item = findPanelWidget(pluginId)
    return !!item && item.opened === true
  }

  function panelWidgetIdAt(region, index) {
    var entries = layoutEntries(String(region || ""))
    var n = Math.round(Number(index)) - 1
    if (n < 0 || n >= entries.length) return ""
    return String(entryId(entries[n]) || "")
  }

  function switchPanelFrom(owner, direction) {
    if (!owner) return false
    var currentSlot = null
    for (var i = 0; i < moduleSlots.length; i++) {
      if (moduleSlots[i] && moduleSlots[i].activeItem === owner) {
        currentSlot = moduleSlots[i]
        break
      }
    }
    if (!currentSlot) return false
    var entries = layoutEntries(currentSlot.region)
    var ids = []
    for (var e = 0; e < entries.length; e++) ids.push(entryId(entries[e]))
    var idx = ids.indexOf(currentSlot.moduleName)
    if (idx < 0 || ids.length < 2) return false
    var step = direction < 0 ? -1 : 1
    for (var n = 1; n < ids.length; n++) {
      var nextId = ids[(idx + step * n + ids.length) % ids.length]
      var item = findPanelWidget(nextId)
      if (item && typeof item.open === "function") {
        item.open()
        return true
      }
    }
    return false
  }

  function run(command) {
    if (!command) return
    Util.execDetached(command)
  }

  function showTooltip(target, text) {
    tooltipTarget = target
    tooltipText = String(text || "")
    tooltipShown = tooltipText !== ""
  }

  function hideTooltip(target) {
    if (tooltipTarget !== target) return
    tooltipShown = false
    tooltipTarget = null
    tooltipText = ""
  }

  function debugBarGeometry() { return [] }
  function toggleTransparency() {}
  function registerClickTarget(target) {}
  function unregisterClickTarget(target) {}

  function openDash() {
    dashOpen = true
    dashDelayTimer.stop()
  }

  function closeDash() {
    if (pinned) return
    dashOpen = false
  }

  function toggleDash() {
    pinned = !pinned
    if (pinned) openDash()
    else dashOpen = false
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
        if (!dashOpen && !pinned) dashDelayTimer.restart()
      } else {
        dashDelayTimer.stop()
        if (!pinned) dashCloseTimer.restart()
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

  function setBarHovered(hovered) {
    barHoverCount = Math.max(0, barHoverCount + (hovered ? 1 : -1))
  }

  Timer { id: dashDelayTimer; interval: root.dashDelay; onTriggered: if (root.topHot) root.openDash() }
  Timer { id: dashCloseTimer; interval: 480; onTriggered: if (!root.topHot && !root.pinned) root.closeDash() }
  Timer { id: leftDelayTimer; interval: 140; onTriggered: if (root.leftHot) root.sessionOpen = true }
  Timer { id: sessionCloseTimer; interval: 180; onTriggered: if (!root.leftHot) root.sessionOpen = false }
  Timer { id: rightDelayTimer; interval: 140; onTriggered: if (root.rightHot) root.utilOpen = true }
  Timer { id: utilCloseTimer; interval: 180; onTriggered: if (!root.rightHot) root.utilOpen = false }

  IpcHandler {
    target: "io.github.gedankenn.magi"
    function toggle(): void { root.toggleDash() }
    function open(): void { root.pinned = true; root.openDash() }
    function close(): void { root.pinned = false; root.dashOpen = false; root.closeSides() }
    function show(): void { root.pinned = true; root.openDash() }
    function hide(): void { root.pinned = false; root.dashOpen = false }
  }

  Variants {
    model: Quickshell.screens
    delegate: Component {
      MagiSurface {
        required property var modelData
        screen: modelData
      }
    }
  }

  component MagiSurface: Item {
    id: seat
    required property var screen

    Dashboard {
      screen: seat.screen
      host: root
      opened: root.dashOpen
      onHoveredChanged: root.bump("top", hovered)
    }
    SessionDrawer {
      screen: seat.screen
      host: root
      opened: root.sessionOpen
      onHoveredChanged: root.bump("left", hovered)
    }
    UtilitiesDrawer {
      screen: seat.screen
      host: root
      opened: root.utilOpen
      onHoveredChanged: root.bump("right", hovered)
    }

    PanelWindow {
      id: sensor
      screen: seat.screen
      anchors { left: true; right: true; top: root.position !== "bottom"; bottom: root.position === "bottom" }
      implicitHeight: root.sensorSize
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "magi-edge-top"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      HoverHandler { onHoveredChanged: root.bump("top", hovered) }
    }

    PanelWindow {
      screen: seat.screen
      anchors { top: true; bottom: true; left: true }
      implicitWidth: root.sensorSize
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "magi-edge-left"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      Rectangle {
        anchors.fill: parent
        color: Color.accent
        opacity: root.sessionOpen ? 0 : 0.45
      }
      HoverHandler { onHoveredChanged: root.bump("left", hovered) }
    }

    PanelWindow {
      screen: seat.screen
      anchors { top: true; bottom: true; right: true }
      implicitWidth: root.sensorSize
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "magi-edge-right"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      Rectangle {
        anchors.fill: parent
        color: Color.accent
        opacity: root.utilOpen ? 0 : 0.45
      }
      HoverHandler { onHoveredChanged: root.bump("right", hovered) }
    }

    PanelWindow {
      id: barWindow
      screen: seat.screen
      visible: true
      exclusionMode: ExclusionMode.Auto
      implicitHeight: root.barSize
      color: "transparent"
      WlrLayershell.namespace: "magi-bar"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      anchors {
        top: root.position !== "bottom"
        bottom: root.position === "bottom"
        left: true
        right: true
      }
      margins {
        top: root.position !== "bottom" ? root.sideGap : 0
        bottom: root.position === "bottom" ? root.sideGap : 0
        left: root.sideGap
        right: root.sideGap
      }

      HoverHandler {
        onHoveredChanged: root.setBarHovered(hovered)
        Component.onDestruction: if (hovered) root.setBarHovered(false)
      }

      BorderSurface {
        id: pill
        anchors.fill: parent
        radius: Math.max(8, Style.cornerRadius + 2)
        color: root.background
        borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))

        Column {
          anchors.fill: parent
          anchors.leftMargin: Style.space(8)
          anchors.rightMargin: Style.space(8)
          anchors.topMargin: 4
          anchors.bottomMargin: 4
          spacing: 2

          Canvas {
            width: parent.width
            height: 5
            onPaint: {
              var ctx = getContext("2d")
              var h = height
              var w = 12
              ctx.clearRect(0, 0, width, h)
              for (var x = -h; x < width + h; x += w) {
                ctx.fillStyle = (Math.floor((x + h) / w) % 2 === 0) ? String(Color.accent) : "#0c0a0d"
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x + 8, 0)
                ctx.lineTo(x + 8 - h, h)
                ctx.lineTo(x - h, h)
                ctx.closePath()
                ctx.fill()
              }
            }
            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
          }

          Item {
            width: parent.width
            height: parent.height - 7

            Row {
              id: leftRow
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0
              Repeater {
                model: root.layoutEntries("left")
                ModuleSlot {
                  required property var modelData
                  entry: modelData
                  region: "left"
                }
              }
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0
              Repeater {
                model: root.layoutEntries("center")
                ModuleSlot {
                  required property var modelData
                  entry: modelData
                  region: "center"
                }
              }
            }

            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0
              Repeater {
                model: root.layoutEntries("right")
                ModuleSlot {
                  required property var modelData
                  entry: modelData
                  region: "right"
                }
              }
            }
          }
        }
      }

      PopupWindow {
        visible: root.tooltipShown && root.tooltipTarget !== null && root.tooltipText !== ""
        color: "transparent"
        implicitWidth: Math.ceil(tipBox.implicitWidth)
        implicitHeight: Math.ceil(tipBox.implicitHeight)
        anchor {
          window: barWindow
          item: root.tooltipTarget
          edges: Edges.Bottom | Edges.Left
          gravity: Edges.Bottom | Edges.Right
        }
        BorderSurface {
          id: tipBox
          color: Color.tooltip.background
          borderSpec: Border.surfaceSpec("tooltip", "border", Color.tooltip.border, 1)
          radius: Style.cornerRadius
          padding: Style.space(6)
          Text {
            text: root.tooltipText
            color: Color.tooltip.text
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }
  }

  component ModuleSlot: Item {
    id: slot
    required property var entry
    property string region: ""
    readonly property string moduleName: root.entryId(entry)
    readonly property var moduleSettings: root.entrySettings(entry)
    readonly property var registryComponent: {
      var w = root.barWidgetRegistry ? root.barWidgetRegistry.widgets : null
      var name = root.canonicalWidgetId(slot.moduleName)
      return w && w[name] ? w[name].component : null
    }
    readonly property var activeItem: loader.item

    implicitWidth: activeItem && activeItem.visible ? activeItem.implicitWidth : 0
    implicitHeight: activeItem && activeItem.visible ? activeItem.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: root.registerModuleSlot(slot)
    Component.onDestruction: root.unregisterModuleSlot(slot)

    Loader {
      id: loader
      active: slot.registryComponent !== null
      sourceComponent: slot.registryComponent
      anchors.fill: parent
      onLoaded: slot.injectProps()
    }

    onActiveItemChanged: Qt.callLater(injectProps)
    onModuleSettingsChanged: injectProps()

    function injectProps() {
      var target = activeItem
      if (!target) return
      if ("bar" in target) target.bar = root
      if ("moduleName" in target) target.moduleName = moduleName
      if ("settings" in target) target.settings = moduleSettings
    }
  }
}
