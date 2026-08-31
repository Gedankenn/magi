import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property var host: null
  property bool opened: false

  readonly property color foreground: Color.menu.text
  readonly property color accent: Color.accent
  readonly property string fontFamily: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"

  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight
  width: parent ? parent.width : implicitWidth
  height: implicitHeight
  opacity: opened ? 1 : 0
  visible: opacity > 0.02
  Behavior on opacity { NumberAnimation { duration: 160 } }

  function run(args) {
    if (!args || !args.length) return
    Quickshell.execDetached(args)
    if (host) host.closeSides()
  }

  Column {
    id: col
    width: root.width
    spacing: Style.space(8)

    Text {
      text: "NERV  //  SESSION"
      color: root.accent
      font.family: root.fontFamily
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
        radius: 0
        color: cell.containsMouse ? Qt.rgba(1, 0.42, 0, 0.22) : Qt.rgba(1, 1, 1, 0.04)
        border.width: cell.containsMouse ? 1 : 0
        border.color: "#FF6A00"
        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: root.foreground
          font.family: root.fontFamily
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
