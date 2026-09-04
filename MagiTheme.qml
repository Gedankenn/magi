import QtQuick

// MAGI color system. Orange is chrome (structure), not content.
// Accents are semantic: acid = live, cyan = weather, violet = media, red = alert.
QtObject {
  id: t

  readonly property color nerv: "#FF6A00"
  readonly property color seele: "#C41E3A"
  readonly property color acid: "#A8FF3E"
  readonly property color cyan: "#7AFFFF"
  readonly property color casper: "#9B6DFF"
  readonly property color paper: "#F4F0E6"
  readonly property color muted: "#B7A99A"
  readonly property color dim: "#8A7A6E"
  readonly property color voidBg: "#0c0a0d"
  readonly property color plate: "#100c10"
  readonly property color pane: "#161218"
  readonly property color paneCool: "#10141a"
  readonly property color paneViolet: "#14101c"
  readonly property color inset: "#0a080c"
  readonly property color raised: "#1c1619"
  readonly property color hairline: "#47FF6A00"
  readonly property color hairlineStrong: "#8CFF6A00"
  readonly property color weekend: "#E0A090"

  readonly property string display: "Chakra Petch"
  readonly property string body: "Nimbus Sans Narrow"
  readonly property string seg: "DSEG7 Classic"

  function wash(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }
}
