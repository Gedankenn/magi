import QtQuick
import Quickshell
import Quickshell.Wayland
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
  readonly property var borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, 1)
  readonly property int cardWidth: Math.max(Math.round(host && host.leftIslandWidth ? host.leftIslandWidth : 0), Style.space(220))
  readonly property real shownX: host && host.sideGap ? host.sideGap : Style.gapsOut
  readonly property real shownY: {
    var gap = host && host.sideGap ? host.sideGap : Style.gapsOut
    var size = host && host.barSize ? host.barSize : Style.bar.sizeHorizontal
    return gap + size + 2
  }

  function run(args) {
    if (!args || !args.length) return
    Quickshell.execDetached(args)
    if (host) host.closeSides()
  }

  PanelWindow {
    screen: root.screen
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: card }

    Rectangle {
      anchors.fill: card
      anchors.margins: -2
      radius: (host && host.islandRadius ? host.islandRadius : 16) + 2
      color: "transparent"
      border.width: 1
      border.color: root.accent
      opacity: 0.28
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: col.implicitHeight + Style.spacing.panelPadding * 2
      radius: host && host.islandRadius ? host.islandRadius : Math.max(8, Style.cornerRadius)
      x: root.shownX
      y: root.opened ? root.shownY : root.shownY - 16
      color: root.background
      borderSpec: root.borderSpec
      opacity: root.opened ? 1 : 0
      Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 160 } }

      HoverHandler { onHoveredChanged: root.hovered = hovered }

      Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.space(8)

        HazardStripe {
          width: parent.width
          height: 7
        }

        Text {
          text: "NERV  //  SESSION"
          color: root.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.6
          font.bold: true
        }

        Repeater {
          model: [
            { label: "LOCK", cmd: ["omarchy", "system", "lock"] },
            { label: "LOGOUT", cmd: ["omarchy", "system", "logout"] },
            { label: "REBOOT", cmd: ["omarchy", "system", "reboot"] },
            { label: "SHUTDOWN", cmd: ["omarchy", "system", "shutdown"] }
          ]
          Rectangle {
            required property var modelData
            width: parent.width
            height: Style.space(30)
            radius: 4
            color: cell.containsMouse ? Qt.rgba(1, 0.42, 0, 0.18) : Qt.rgba(1, 1, 1, 0.04)
            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: root.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.letterSpacing: 1.4
            }
            MouseArea {
              id: cell
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.run(modelData.cmd)
            }
          }
        }
      }
    }
  }
}
