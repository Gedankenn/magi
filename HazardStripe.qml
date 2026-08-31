import QtQuick
import qs.Commons

Canvas {
  id: root
  property color stripe: Color.accent
  property color gap: "#0c0a0d"
  property int pitch: 12

  onPaint: {
    var ctx = getContext("2d")
    var h = height
    var w = Math.max(6, pitch)
    ctx.clearRect(0, 0, width, h)
    for (var x = -h; x < width + h; x += w) {
      ctx.fillStyle = (Math.floor((x + h) / w) % 2 === 0) ? String(root.stripe) : String(root.gap)
      ctx.beginPath()
      ctx.moveTo(x, 0)
      ctx.lineTo(x + w * 0.7, 0)
      ctx.lineTo(x + w * 0.7 - h, h)
      ctx.lineTo(x - h, h)
      ctx.closePath()
      ctx.fill()
    }
  }

  Component.onCompleted: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onStripeChanged: requestPaint()
}
