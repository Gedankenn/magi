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

  readonly property string home: Quickshell.env("HOME")
  readonly property string omarchyConfigDir: home + "/.config/omarchy"

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

  property color foreground: "#F4F0E6"
  property color barForeground: foreground
  property color background: Color.menu.background
  property color urgent: Color.bar.active
  property string fontFamily: "Nimbus Sans Narrow"

  property bool pinned: false
  property bool dashOpen: false
  property bool sessionOpen: false
  property bool utilOpen: false
  property int dashSerial: 0
  property bool dashIslandHot: false
  property bool dashMenuHot: false
  property bool sessionIslandHot: false
  property bool sessionMenuHot: false
  property bool utilIslandHot: false
  property bool utilMenuHot: false
  readonly property bool topHot: dashIslandHot || dashMenuHot
  readonly property bool leftHot: sessionIslandHot || sessionMenuHot
  readonly property bool rightHot: utilIslandHot || utilMenuHot
  readonly property bool anyMenuOpen: dashOpen || sessionOpen || utilOpen
  readonly property bool barBusy: barHovered || !!activePopout || anyMenuOpen

  property var layoutConfig: ({ left: [], center: [], right: [] })
  property int barConfigSerial: 0
  readonly property int dashDelay: 0
  readonly property int hideDelay: 520
  readonly property int sideGap: Style.gapsOut
  readonly property int islandPadX: Style.space(10)
  readonly property int islandRadius: 0
  property real leftIslandX: 0
  property real leftIslandWidth: 0
  property real centerIslandX: 0
  property real centerIslandWidth: 0
  property real rightIslandX: 0
  property real rightIslandWidth: 0

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
  function customModuleType(entry) { return Model.customModuleType(entry) }
  function customModuleSource(entry) {
    var source = Model.customModulePath(entry, home, omarchyConfigDir)
    return source ? Util.fileUrl(source) : ""
  }

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
    // Layer-shell popups on hover crash Hyprland (zwlr protocol error).
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
    sessionOpen = false
    utilOpen = false
    dashOpen = true
    dashDelayTimer.stop()
    hideTooltip(tooltipTarget)
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
    if (!pinned) dashOpen = false
  }

  function setIslandHot(edge, hovered) {
    if (edge === "top") dashIslandHot = hovered
    else if (edge === "left") sessionIslandHot = hovered
    else if (edge === "right") utilIslandHot = hovered
    if (hovered) {
      if (edge === "top") { sessionOpen = false; utilOpen = false; dashOpen = true; dashCloseTimer.stop(); dashDelayTimer.stop() }
      else if (edge === "left") { if (!pinned) dashOpen = false; utilOpen = false; sessionOpen = true; sessionCloseTimer.stop(); leftDelayTimer.stop() }
      else if (edge === "right") { if (!pinned) dashOpen = false; sessionOpen = false; utilOpen = true; utilCloseTimer.stop(); rightDelayTimer.stop() }
    } else {
      syncHover(edge)
    }
  }

  function setMenuHot(edge, hovered) {
    if (edge === "top") dashMenuHot = hovered
    else if (edge === "left") sessionMenuHot = hovered
    else if (edge === "right") utilMenuHot = hovered
    syncHover(edge)
  }

  function syncHover(edge) {
    if (edge === "top") {
      if (topHot || pinned) {
        sessionOpen = false
        utilOpen = false
        if (!dashOpen) dashDelayTimer.restart()
        dashCloseTimer.stop()
      } else {
        dashDelayTimer.stop()
        if (!pinned) dashCloseTimer.restart()
      }
    } else if (edge === "left") {
      if (leftHot) {
        if (!pinned) dashOpen = false
        utilOpen = false
        leftDelayTimer.restart()
        sessionCloseTimer.stop()
      } else {
        leftDelayTimer.stop()
        sessionCloseTimer.restart()
      }
    } else if (edge === "right") {
      if (rightHot) {
        if (!pinned) dashOpen = false
        sessionOpen = false
        rightDelayTimer.restart()
        utilCloseTimer.stop()
      } else {
        rightDelayTimer.stop()
        utilCloseTimer.restart()
      }
    }
  }

  function setBarHovered(hovered) {
    barHoverCount = Math.max(0, barHoverCount + (hovered ? 1 : -1))
  }

  Timer { id: dashDelayTimer; interval: root.dashDelay; onTriggered: if (root.topHot || root.pinned) root.openDash() }
  Timer { id: dashCloseTimer; interval: root.hideDelay; onTriggered: if (!root.topHot && !root.pinned) root.closeDash() }
  Timer { id: leftDelayTimer; interval: root.dashDelay; onTriggered: if (root.leftHot) root.sessionOpen = true }
  Timer { id: sessionCloseTimer; interval: root.hideDelay; onTriggered: if (!root.leftHot) root.sessionOpen = false }
  Timer { id: rightDelayTimer; interval: root.dashDelay; onTriggered: if (root.rightHot) root.utilOpen = true }
  Timer { id: utilCloseTimer; interval: root.hideDelay; onTriggered: if (!root.rightHot) root.utilOpen = false }

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

    readonly property int dropTop: root.sideGap + root.barSize - 2
    readonly property int screenW: screen ? Math.round(screen.width) : 1920
    readonly property int sessionW: Style.space(240)
    readonly property int sessionH: Style.space(188)
    readonly property int dashW: Style.space(640)
    readonly property int dashH: Style.space(268)
    readonly property int utilW: Style.space(260)
    readonly property int utilH: Style.space(228)

    function clampX(x, w) {
      return Math.max(0, Math.min(seat.screenW - w, Math.round(x)))
    }

    readonly property int sessionX: seat.clampX(root.sideGap + root.leftIslandX, sessionW)
    readonly property int dashX: {
      var cx = root.sideGap + root.centerIslandX + root.centerIslandWidth / 2
      return seat.clampX(cx - dashW / 2, dashW)
    }
    readonly property int utilX: seat.clampX(root.sideGap + root.rightIslandX + root.rightIslandWidth - utilW, utilW)

    PanelWindow {
      id: barWindow
      screen: seat.screen
      visible: true
      exclusionMode: ExclusionMode.Auto
      implicitHeight: root.barSize
      color: "transparent"
      WlrLayershell.namespace: "magi-bar"
      WlrLayershell.layer: WlrLayer.Top
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

      mask: Region {
        Region { item: leftIsland }
        Region { item: centerIsland }
        Region { item: rightIsland }
      }

      MagiIsland {
        id: leftIsland
        tag: "NERV"
        edge: "left"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        onXChanged: root.leftIslandX = x
        onWidthChanged: root.leftIslandWidth = width
        Component.onCompleted: { root.leftIslandX = x; root.leftIslandWidth = width }
        Repeater {
          model: root.layoutEntries("left")
          ModuleSlot {
            required property var modelData
            entry: modelData
            region: "left"
          }
        }
      }

      MagiIsland {
        id: centerIsland
        tag: "MAGI"
        edge: "top"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        onXChanged: root.centerIslandX = x
        onWidthChanged: root.centerIslandWidth = width
        Component.onCompleted: { root.centerIslandX = x; root.centerIslandWidth = width }
        Repeater {
          model: root.layoutEntries("center")
          ModuleSlot {
            required property var modelData
            entry: modelData
            region: "center"
          }
        }
      }

      MagiIsland {
        id: rightIsland
        tag: "SYS"
        edge: "right"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        onXChanged: root.rightIslandX = x
        onWidthChanged: root.rightIslandWidth = width
        Component.onCompleted: { root.rightIslandX = x; root.rightIslandWidth = width }
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

    MagiDropWindow {
      screen: seat.screen
      edge: "left"
      opened: root.sessionOpen
      menuSource: "SessionDrawer.qml"
      namespaceName: "magi-session"
      fixedWidth: seat.sessionW
      fixedHeight: seat.sessionH
      posX: seat.sessionX
    }

    MagiDropWindow {
      screen: seat.screen
      edge: "top"
      opened: root.dashOpen
      menuSource: "Dashboard.qml"
      namespaceName: "magi-dash"
      fixedWidth: seat.dashW
      fixedHeight: seat.dashH
      posX: seat.dashX
    }

    MagiDropWindow {
      screen: seat.screen
      edge: "right"
      opened: root.utilOpen
      menuSource: "UtilitiesDrawer.qml"
      namespaceName: "magi-util"
      fixedWidth: seat.utilW
      fixedHeight: seat.utilH
      posX: seat.utilX
    }
  }

  component MagiDropWindow: PanelWindow {
    id: dropWin
    property string edge: ""
    property bool opened: false
    property string menuSource: ""
    property string namespaceName: "magi-drop"
    property int fixedWidth: 240
    property int fixedHeight: 200
    property int posX: 0

    visible: opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: fixedWidth
    implicitHeight: fixedHeight
    WlrLayershell.namespace: namespaceName
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; left: true }
    margins {
      top: root.sideGap + root.barSize - 2
      left: posX
    }

    Item {
      anchors.fill: parent

      HoverHandler {
        blocking: false
        enabled: dropWin.opened
        onHoveredChanged: root.setMenuHot(dropWin.edge, hovered)
        Component.onDestruction: root.setMenuHot(dropWin.edge, false)
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onContainsMouseChanged: root.setMenuHot(dropWin.edge, containsMouse)
      }

      BorderSurface {
        id: plate
        anchors.fill: parent
        radius: root.islandRadius
        color: root.background
        borderSpec: Border.flat("#FF6A00", 2)

        Loader {
          anchors.fill: parent
          anchors.margins: Style.space(10)
          active: dropWin.menuSource !== ""
          source: dropWin.menuSource
          onLoaded: {
            if (!item) return
            item.host = root
            item.opened = Qt.binding(function() { return dropWin.opened })
          }
        }
      }
    }
  }

  component MagiIsland: Item {
    id: island
    property string tag: ""
    property string edge: ""
    default property alias extra: chipRow.data

    readonly property real headerWidth: tagLabel.implicitWidth + chipRow.implicitWidth + root.islandPadX * 2 + (tagLabel.visible ? Style.space(8) : 0)

    implicitWidth: Math.max(root.barSize, headerWidth)
    implicitHeight: root.barSize
    width: implicitWidth
    height: implicitHeight

    HoverHandler {
      blocking: false
      onHoveredChanged: root.setIslandHot(island.edge, hovered)
      Component.onDestruction: root.setIslandHot(island.edge, false)
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      onContainsMouseChanged: root.setIslandHot(island.edge, containsMouse)
    }

    BorderSurface {
      id: plate
      width: parent.width
      height: parent.height
      radius: root.islandRadius
      color: root.background
      borderSpec: Border.flat("#FF6A00", 2)
      clip: true

      HazardStripe {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 11
      }

      Row {
        id: headerRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(8)
        height: Style.bar.sizeHorizontal

        Text {
          id: tagLabel
          visible: island.tag !== ""
          text: island.tag
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 2.4
          font.bold: true
          font.capitalization: Font.AllUppercase
          anchors.verticalCenter: parent.verticalCenter
        }

        Row {
          id: chipRow
          spacing: Style.space(4)
          height: parent.height
          anchors.verticalCenter: parent.verticalCenter
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
    readonly property string customType: root.customModuleType(entry)
    readonly property var registryComponent: {
      var w = root.barWidgetRegistry ? root.barWidgetRegistry.widgets : null
      if (customType) return null
      var name = root.canonicalWidgetId(slot.moduleName)
      return w && w[name] ? w[name].component : null
    }
    readonly property bool qmlCustom: customType === "qml"
    readonly property bool registered: registryComponent !== null
    readonly property var activeItem: {
      if (registered) return registryLoader.item
      if (qmlCustom) return qmlLoader.item
      return null
    }

    implicitWidth: activeItem && activeItem.visible ? activeItem.implicitWidth : 0
    implicitHeight: activeItem && activeItem.visible ? activeItem.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: root.registerModuleSlot(slot)
    Component.onDestruction: root.unregisterModuleSlot(slot)

    HoverHandler {
      blocking: false
      onHoveredChanged: {
        var edge = slot.region === "left" ? "left" : (slot.region === "right" ? "right" : "top")
        root.setIslandHot(edge, hovered)
      }
      Component.onDestruction: {
        var edge = slot.region === "left" ? "left" : (slot.region === "right" ? "right" : "top")
        root.setIslandHot(edge, false)
      }
    }

    Loader {
      id: registryLoader
      active: slot.registered
      sourceComponent: slot.registered ? slot.registryComponent : null
      anchors.fill: parent
      onLoaded: slot.injectProps()
    }

    Loader {
      id: qmlLoader
      active: slot.qmlCustom
      source: slot.qmlCustom ? root.customModuleSource(slot.entry) : ""
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
