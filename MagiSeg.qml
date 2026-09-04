import QtQuick

// 7-segment readout with ghost digits and a restrained NERV bloom.
Item {
  id: root

  property string value: "00:00"
  property string ghost: "88:88"
  property color ink: "#FF6A00"
  property int pixelSize: 26
  property real tracking: 2
  property string family: "DSEG7 Classic"
  property bool glow: false

  implicitWidth: g.implicitWidth
  implicitHeight: g.implicitHeight

  Rectangle {
    visible: root.glow
    anchors.centerIn: g
    width: g.width + Math.round(root.pixelSize * 0.9)
    height: g.height + Math.round(root.pixelSize * 0.45)
    radius: Math.round(root.pixelSize * 0.35)
    z: -1
    color: root.ink
    opacity: 0.11
  }

  Text {
    id: g
    text: root.ghost
    color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.14)
    font.family: root.family
    font.pixelSize: root.pixelSize
    font.letterSpacing: root.tracking
  }

  Text {
    anchors.fill: g
    text: root.value
    color: root.ink
    font.family: root.family
    font.pixelSize: root.pixelSize
    font.letterSpacing: root.tracking
  }
}
