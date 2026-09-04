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
      MagiBtn {
        required property var modelData
        width: parent.width
        height: 36
        label: modelData.label
        accent: root.accent
        paper: root.paper
        displayFont: root.displayFont
        danger: modelData.danger
        pixelSize: 13
        tracking: 2
        onHover: function(on) { root.holdMenu(on) }
        onClicked: root.run(modelData.cmd)
      }
    }
  }
}
