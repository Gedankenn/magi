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
  readonly property var borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
  readonly property int cardWidth: Style.space(240)
  readonly property real parkedX: -cardWidth - 20
  readonly property real shownX: Style.gapsOut

  function run(args) {
    if (!args || !args.length) return
    Quickshell.execDetached(args)
    if (host) host.closeSides()
  }

  PanelWindow {
    screen: root.screen
    visible: root.opened || card.x > root.parkedX + 2
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "magi-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    BorderSurface {
      id: card
      width: root.cardWidth
      height: col.implicitHeight + Style.spacing.panelPadding * 2
      radius: Math.max(6, Style.cornerRadius)
      x: root.opened ? root.shownX : root.parkedX
      anchors.verticalCenter: parent.verticalCenter
      color: root.background
      borderSpec: root.borderSpec
      Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

      HoverHandler { onHoveredChanged: root.hovered = hovered }

      Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.space(8)

        Text {
          text: "NERV  //  SESSION"
          color: root.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.8
          font.bold: true
        }
        Text {
          text: "END OF DUTY"
          color: Qt.darker(root.foreground, 1.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.2
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
            height: Style.space(32)
            radius: 4
            color: cell.containsMouse ? Qt.rgba(1, 0.42, 0, 0.18) : Qt.rgba(1, 1, 1, 0.04)
            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: root.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.letterSpacing: 1.6
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
