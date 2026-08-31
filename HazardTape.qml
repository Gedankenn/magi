import QtQuick
import qs.Commons

// Hazard-tape band with diagonal-cut ends and an optional punched stencil
// label (NERV/MAGI/SYS). Draws the classic 45deg warning stripes, carves the
// two ends on a diagonal so the tape visibly terminates, and punches a label
// out of the center in the theme gap color.
Canvas {
  id: root

  property color stripe: "#FF6A00"
  property color gap: "#0c0a0d"
  property int pitch: 18
  property real endInset: 6
  property string label: ""
  property string labelFont: "Chakra Petch"

  onPaint: {
    var ctx = getContext("2d")
    var h = height
    var w = Math.max(8, pitch)
    var inset = Math.max(0, endInset)
    ctx.clearRect(0, 0, width, h)

    var x
    for (x = -h; x < width + h; x += w) {
      ctx.fillStyle = (Math.floor((x + h) / w) % 2 === 0) ? String(root.stripe) : String(root.gap)
      ctx.beginPath()
      ctx.moveTo(x, 0)
      ctx.lineTo(x + w * 0.5, 0)
      ctx.lineTo(x + w * 0.5 - h, h)
      ctx.lineTo(x - h, h)
      ctx.closePath()
      ctx.fill()
    }

    if (inset > 0 && width > inset * 3) {
      ctx.save()
      ctx.globalCompositeOperation = "destination-out"
      ctx.beginPath()
      ctx.moveTo(0, 0)
      ctx.lineTo(inset, 0)
      ctx.lineTo(0, h)
      ctx.closePath()
      ctx.fill()
      ctx.beginPath()
      ctx.moveTo(width, 0)
      ctx.lineTo(width - inset, 0)
      ctx.lineTo(width, h)
      ctx.closePath()
      ctx.fill()
      ctx.restore()
    }

    if (root.label !== "" && width > 60) {
      var lh = Math.max(9, Math.round(h * 0.72))
      ctx.save()
      var ledgerMargin = 3
      var ledgerW = ctx.measureText(root.label).width + ledgerMargin * 2
      ledgerW = Math.min(ledgerW, width - inset * 2 - 8)
      var ledgerX = (width - ledgerW) / 2
      ctx.fillStyle = String(root.gap)
      ctx.fillRect(ledgerX, (h - lh) / 2, ledgerW, lh)
      ctx.font = "600 " + lh + "px \"" + root.labelFont + "\""
      ctx.textAlign = "center"
      ctx.textBaseline = "middle"
      ctx.fillStyle = String(root.stripe)
      ctx.fillText(root.label, width / 2, h / 2 + 1)
      ctx.restore()
    }
  }

  Component.onCompleted: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onStripeChanged: requestPaint()
  onLabelChanged: requestPaint()
}
