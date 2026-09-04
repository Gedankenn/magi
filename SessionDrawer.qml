import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property var host: null
  property bool opened: false
  property string edge: "left"

  function holdMenu(on) {
    if (host && typeof host.setMenuHot === "function") host.setMenuHot(edge, on)
  }

  HoverHandler {
    blocking: false
    onHoveredChanged: root.holdMenu(hovered)
  }

  readonly property color paper: "#F4F0E6"
  readonly property color accent: "#FF6A00"
  readonly property color blood: "#C41E3A"
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
  readonly property string displayFont: host && host.displayFont ? host.displayFont : "Chakra Petch"

  width: parent ? parent.width : 300
  height: parent ? parent.height : 240
  opacity: opened ? 1 : 0
  visible: opacity > 0.02
  Behavior on opacity { NumberAnimation { duration: 160 } }

  function run(args) {
    if (!args || !args.length) return
    Quickshell.execDetached(args)
    if (host) host.closeSides()
  }

  Column {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 8

    Text {
      text: "COMMAND AUTHORITY"
      color: root.accent
      font.family: root.displayFont
      font.pixelSize: 12
      font.letterSpacing: 2.5
      font.weight: 600
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(1, 0.42, 0, 0.35)
    }

    Repeater {
      model: [
        { label: "LOCK", cmd: ["omarchy", "system", "lock"], danger: false },
        { label: "LOGOUT", cmd: ["omarchy", "system", "logout"], danger: false },
        { label: "REBOOT", cmd: ["omarchy", "system", "reboot"], danger: true },
        { label: "SHUTDOWN", cmd: ["omarchy", "system", "shutdown"], danger: true }
      ]
      Rectangle {
        required property var modelData
        width: parent.width
        height: 36
        color: cell.containsMouse ? (modelData.danger ? Qt.rgba(0.77, 0.12, 0.23, 0.35) : Qt.rgba(1, 0.42, 0, 0.22)) : "#141014"
        border.width: 1
        border.color: cell.containsMouse ? (modelData.danger ? root.blood : root.accent) : Qt.rgba(1, 0.42, 0, 0.28)
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: root.paper
          font.family: root.displayFont
          font.pixelSize: 13
          font.letterSpacing: 2
          font.weight: 600
        }
        MouseArea {
          id: cell
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.holdMenu(true)
          onExited: root.holdMenu(false)
          onClicked: root.run(modelData.cmd)
        }
      }
    }
  }
}
