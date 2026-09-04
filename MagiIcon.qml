import QtQuick

// MAGI HUD glyphs: weather, core marks, warning triangle.
Canvas {
  id: root

  property string kind: "cloud"
  property color stroke: "#A8FF3E"
  property color accent: "#7AFFFF"
  width: 22
  height: 22

  onPaint: {
    var ctx = getContext("2d")
    var s = Math.min(width, height) / 24
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.clearRect(0, 0, width, height)
    ctx.translate((width - 24 * s) / 2, (height - 24 * s) / 2)
    ctx.scale(s, s)
    ctx.lineJoin = "round"
    ctx.lineCap = "round"
    var k = String(root.kind || "cloud")
    if (k === "warn") drawWarn(ctx)
    else if (k === "sun") drawSun(ctx)
    else if (k === "cloud") drawCloud(ctx, false)
    else if (k === "rain" || k === "balthasar") drawRain(ctx)
    else if (k === "storm") drawStorm(ctx)
    else if (k === "snow") drawSnow(ctx)
    else if (k === "fog") drawFog(ctx)
    else if (k === "chip" || k === "melchior") drawChip(ctx)
    else if (k === "cal" || k === "sachiel") drawCal(ctx)
    else if (k === "wave" || k === "casper") drawWave(ctx)
    else drawCloud(ctx, false)
  }

  function strokeColor() { return String(root.stroke) }
  function accentColor() { return String(root.accent) }

  function drawWarn(ctx) {
    ctx.lineWidth = 1.8
    ctx.strokeStyle = strokeColor()
    ctx.fillStyle = Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.15)
    ctx.beginPath()
    ctx.moveTo(12, 3)
    ctx.lineTo(22, 21)
    ctx.lineTo(2, 21)
    ctx.closePath()
    ctx.fill()
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(12, 9)
    ctx.lineTo(12, 14.5)
    ctx.stroke()
    ctx.beginPath()
    ctx.arc(12, 17.6, 1.1, 0, Math.PI * 2)
    ctx.fillStyle = strokeColor()
    ctx.fill()
  }

  function cloudPath(ctx) {
    ctx.beginPath()
    ctx.moveTo(6.5, 14.5)
    ctx.bezierCurveTo(3.2, 14.5, 2.2, 11.4, 4.4, 10)
    ctx.bezierCurveTo(4.2, 6.6, 8.4, 5.2, 10.4, 7.4)
    ctx.bezierCurveTo(11.6, 4.4, 17.2, 4.6, 18.2, 8.2)
    ctx.bezierCurveTo(21.6, 8.4, 22.2, 13.2, 19.2, 14.5)
    ctx.closePath()
  }

  function drawCloud(ctx, filled) {
    ctx.lineWidth = 1.7
    ctx.strokeStyle = accentColor()
    ctx.fillStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
    cloudPath(ctx)
    if (filled !== false) ctx.fill()
    ctx.stroke()
  }

  function drawRain(ctx) {
    drawCloud(ctx, true)
    ctx.strokeStyle = strokeColor()
    ctx.lineWidth = 1.7
    ctx.beginPath(); ctx.moveTo(8, 17.2); ctx.lineTo(8, 21.4); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(12, 16.4); ctx.lineTo(12, 22); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(16, 17.2); ctx.lineTo(16, 21.4); ctx.stroke()
  }

  function drawStorm(ctx) {
    drawCloud(ctx, true)
    ctx.fillStyle = strokeColor()
    ctx.beginPath()
    ctx.moveTo(13.2, 14.2)
    ctx.lineTo(10.2, 18.6)
    ctx.lineTo(12.4, 18.6)
    ctx.lineTo(11.2, 22.2)
    ctx.lineTo(16.2, 16.6)
    ctx.lineTo(13.6, 16.6)
    ctx.closePath()
    ctx.fill()
  }

  function drawSnow(ctx) {
    drawCloud(ctx, true)
    ctx.strokeStyle = strokeColor()
    ctx.lineWidth = 1.3
    function flake(x, y) {
      ctx.beginPath(); ctx.moveTo(x - 1.6, y); ctx.lineTo(x + 1.6, y); ctx.stroke()
      ctx.beginPath(); ctx.moveTo(x, y - 1.6); ctx.lineTo(x, y + 1.6); ctx.stroke()
    }
    flake(8.5, 19.2)
    flake(12, 21)
    flake(16, 19.2)
  }

  function drawSun(ctx) {
    ctx.strokeStyle = strokeColor()
    ctx.fillStyle = Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.14)
    ctx.lineWidth = 1.7
    ctx.beginPath()
    ctx.arc(12, 12, 4.2, 0, Math.PI * 2)
    ctx.fill()
    ctx.stroke()
    for (var i = 0; i < 8; i++) {
      var a = i * Math.PI / 4
      ctx.beginPath()
      ctx.moveTo(12 + Math.cos(a) * 6.6, 12 + Math.sin(a) * 6.6)
      ctx.lineTo(12 + Math.cos(a) * 10.1, 12 + Math.sin(a) * 10.1)
      ctx.stroke()
    }
  }

  function drawFog(ctx) {
    ctx.strokeStyle = accentColor()
    ctx.lineWidth = 1.7
    ctx.beginPath(); ctx.moveTo(4, 8); ctx.lineTo(20, 8); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(6, 12); ctx.lineTo(18, 12); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(5, 16); ctx.lineTo(19, 16); ctx.stroke()
  }

  function drawChip(ctx) {
    ctx.strokeStyle = strokeColor()
    ctx.fillStyle = Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.14)
    ctx.lineWidth = 1.6
    ctx.beginPath()
    ctx.rect(5, 5, 14, 14)
    ctx.fill()
    ctx.stroke()
    ctx.lineWidth = 1.5
    ctx.beginPath(); ctx.moveTo(9, 2.5); ctx.lineTo(9, 5); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(15, 2.5); ctx.lineTo(15, 5); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(9, 19); ctx.lineTo(9, 21.5); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(15, 19); ctx.lineTo(15, 21.5); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(2.5, 9); ctx.lineTo(5, 9); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(2.5, 15); ctx.lineTo(5, 15); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(19, 9); ctx.lineTo(21.5, 9); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(19, 15); ctx.lineTo(21.5, 15); ctx.stroke()
    ctx.lineWidth = 1.2
    ctx.beginPath()
    ctx.rect(8.5, 8.5, 7, 7)
    ctx.stroke()
  }

  function drawCal(ctx) {
    ctx.strokeStyle = strokeColor()
    ctx.fillStyle = Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.12)
    ctx.lineWidth = 1.6
    ctx.beginPath()
    ctx.rect(4, 5.5, 16, 15)
    ctx.fill()
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(4, 10)
    ctx.lineTo(20, 10)
    ctx.stroke()
    ctx.beginPath(); ctx.moveTo(8, 3.5); ctx.lineTo(8, 7.5); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(16, 3.5); ctx.lineTo(16, 7.5); ctx.stroke()
    ctx.fillStyle = strokeColor()
    ctx.fillRect(7, 13, 2.2, 2.2)
    ctx.fillRect(11, 13, 2.2, 2.2)
    ctx.fillRect(15, 13, 2.2, 2.2)
  }

  function drawWave(ctx) {
    ctx.strokeStyle = strokeColor()
    ctx.lineWidth = 1.8
    ctx.beginPath()
    ctx.moveTo(1, 12)
    ctx.bezierCurveTo(4, 12, 4, 5, 8, 5)
    ctx.bezierCurveTo(12, 5, 12, 19, 16, 19)
    ctx.bezierCurveTo(20, 19, 20, 12, 23, 12)
    ctx.stroke()
  }

  Component.onCompleted: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onKindChanged: requestPaint()
  onStrokeChanged: requestPaint()
  onAccentChanged: requestPaint()
}
