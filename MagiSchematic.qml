import QtQuick
import qs.Commons

Item {
  id: root

  property var host: null
  property bool opened: false
  property string edge: "left"
  property string unitId: ""

  readonly property string unit: unitId !== "" ? unitId : (edge === "right" ? "01" : "02")
  readonly property bool is01: unit === "01"
  readonly property color ink: is01 ? "#9B6DFF" : "#FF6A00"
  readonly property color accent: is01 ? "#A8FF3E" : "#C41E3A"
  readonly property color paper: "#F4F0E6"
  readonly property string displayFont: host && host.displayFont ? host.displayFont : "Chakra Petch"
  readonly property string bodyFont: host && host.fontFamily ? host.fontFamily : "Nimbus Sans Narrow"
  readonly property string pilot: is01 ? "IKARI SHINJI" : "SORYU ASUKA LANGLEY"
  readonly property string modelName: is01 ? "TEST TYPE" : "PRODUCTION MODEL"
  readonly property string status: is01 ? "S2 ORGAN  //  SYNC READY" : "TYPE-B  //  STANDBY"
  readonly property string plate: Qt.resolvedUrl(is01 ? "assets/unit-01.jpg" : "assets/unit-02.jpg")

  property real tick: 0

  function holdMenu(on) {
    if (host && typeof host.setMenuHot === "function") host.setMenuHot(edge, on)
  }

  HoverHandler {
    blocking: false
    onHoveredChanged: root.holdMenu(hovered)
  }

  Timer {
    interval: 33
    running: root.opened && root.visible
    repeat: true
    onTriggered: {
      root.tick += 0.033
      hud.requestPaint()
    }
  }

  Item {
    id: stage
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: spec.top
    anchors.margins: 6
    clip: true

    Image {
      id: mecha
      anchors.fill: parent
      source: root.plate
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: true
      smooth: true
    }

    Canvas {
      id: hud
      anchors.fill: mecha
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()

      onPaint: {
        var ctx = getContext("2d")
        var w = hud.width
        var h = hud.height
        ctx.setTransform(1, 0, 0, 1, 0, 0)
        ctx.clearRect(0, 0, w, h)
        if (w < 20 || h < 20) return

        var t = root.tick
        var acc = String(root.accent)
        var ink = String(root.ink)
        var pulse = 0.4 + 0.6 * Math.sin(t * 2.2)
        var scan = (t * 0.32) % 1

        function rgba(c, a) {
          var r = parseInt(c.slice(1, 3), 16)
          var g = parseInt(c.slice(3, 5), 16)
          var b = parseInt(c.slice(5, 7), 16)
          return "rgba(" + r + "," + g + "," + b + "," + a + ")"
        }

        ctx.strokeStyle = rgba(ink, 0.12)
        ctx.lineWidth = 1
        var g
        for (g = 0; g < w; g += 28) {
          ctx.beginPath(); ctx.moveTo(g, 0); ctx.lineTo(g, h); ctx.stroke()
        }
        for (g = 0; g < h; g += 28) {
          ctx.beginPath(); ctx.moveTo(0, g); ctx.lineTo(w, g); ctx.stroke()
        }

        ctx.save()
        ctx.translate(w * 0.52, h * 0.42)
        ctx.rotate(t * 0.22)
        ctx.strokeStyle = rgba(acc, 0.22 + 0.18 * pulse)
        ctx.lineWidth = 1.4
        ctx.setLineDash([7, 5])
        var fieldR = Math.min(w, h) * 0.28
        ctx.beginPath()
        var i
        for (i = 0; i < 6; i++) {
          var a = i * Math.PI / 3 - Math.PI / 6
          var px = Math.cos(a) * fieldR
          var py = Math.sin(a) * fieldR * 0.92
          if (i === 0) ctx.moveTo(px, py)
          else ctx.lineTo(px, py)
        }
        ctx.closePath()
        ctx.stroke()
        ctx.restore()
        ctx.setLineDash([])

        var scanY = 8 + scan * (h - 16)
        var grad = ctx.createLinearGradient(0, scanY - 28, 0, scanY + 6)
        grad.addColorStop(0, rgba(acc, 0))
        grad.addColorStop(0.75, rgba(acc, 0.16))
        grad.addColorStop(1, rgba(acc, 0))
        ctx.fillStyle = grad
        ctx.fillRect(0, scanY - 28, w, 34)
        ctx.strokeStyle = rgba(acc, 0.7)
        ctx.lineWidth = 1.2
        ctx.beginPath()
        ctx.moveTo(10, scanY)
        ctx.lineTo(w - 10, scanY)
        ctx.stroke()

        ctx.fillStyle = rgba(acc, 0.12 + 0.18 * pulse)
        ctx.beginPath()
        ctx.arc(w * 0.52, h * 0.40, 10 + 4 * pulse, 0, Math.PI * 2)
        ctx.fill()
      }
    }
  }

  Item {
    id: spec
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 74

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      height: 1
      color: root.ink
      opacity: 0.4
    }

    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      spacing: 3

      Text {
        width: parent.width
        text: "EVA-" + root.unit + "   " + root.modelName
        color: root.ink
        font.family: root.displayFont
        font.pixelSize: 12
        font.letterSpacing: 1.8
        font.weight: 600
      }
      Text {
        width: parent.width
        text: "PILOT  //  " + root.pilot
        color: root.paper
        font.family: root.displayFont
        font.pixelSize: 11
        font.letterSpacing: 1.4
      }
      Text {
        width: parent.width
        text: root.status
        color: root.accent
        font.family: root.bodyFont
        font.pixelSize: 11
        font.letterSpacing: 1.2
      }
    }
  }
}
