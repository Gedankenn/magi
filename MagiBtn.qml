import QtQuick

// HUD control. Geometry stays put across states; only fill/border shift.
Rectangle {
  id: root

  property string label: ""
  property color accent: "#FF6A00"
  property color paper: "#F4F0E6"
  property string displayFont: "Chakra Petch"
  property bool primary: false
  property bool danger: false
  property int pixelSize: 11
  property real tracking: 1.4

  signal clicked()
  signal hover(bool on)

  readonly property color ink: root.danger ? "#C41E3A" : root.accent
  readonly property bool hot: hit.containsMouse
  readonly property bool down: hit.pressed

  implicitWidth: 64
  implicitHeight: 30
  color: {
    var a = root.down ? (root.primary ? 0.58 : 0.32)
      : root.hot ? (root.primary ? 0.44 : 0.18)
      : (root.primary ? 0.28 : 0.0)
    if (a <= 0) return "#1c1619"
    return Qt.rgba(root.ink.r, root.ink.g, root.ink.b, a)
  }
  border.width: 1
  border.color: (root.hot || root.primary || root.down)
    ? root.ink
    : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.42)
  Behavior on color { ColorAnimation { duration: 90 } }
  Behavior on border.color { ColorAnimation { duration: 90 } }

  Text {
    anchors.centerIn: parent
    text: root.label
    color: root.paper
    font.family: root.displayFont
    font.pixelSize: root.pixelSize
    font.letterSpacing: root.tracking
    font.weight: 600
  }

  MouseArea {
    id: hit
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
    onEntered: root.hover(true)
    onExited: root.hover(false)
  }
}
