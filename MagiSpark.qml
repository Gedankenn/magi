import QtQuick

Item {
  id: root

  property var seriesA: []
  property var seriesB: []
  property color colorA: "#FF6A00"
  property color colorB: "#A8FF3E"
  property real minValue: 0
  property real maxValue: 0
  property string labelA: ""
  property string labelB: ""
  property string valueA: ""
  property string valueB: ""
  property string scaleLow: ""
  property string scaleHigh: ""
  property string displayFont: "Chakra Petch"
  property string bodyFont: "Nimbus Sans Narrow"

  onSeriesAChanged: chart.requestPaint()
  onSeriesBChanged: chart.requestPaint()
  onWidthChanged: chart.requestPaint()
  onHeightChanged: chart.requestPaint()
  onMinValueChanged: chart.requestPaint()
  onMaxValueChanged: chart.requestPaint()

  Rectangle {
    anchors.fill: parent
    color: "#141014"
    border.width: 1
    border.color: "#FF6A00"
  }

  Column {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 4

    Item {
      width: parent.width
      height: 16

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.labelB + "  " + root.valueB
        color: root.colorB
        font.family: root.bodyFont
        font.pixelSize: 13
        font.bold: true
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.labelA + "  " + root.valueA
        color: root.colorA
        font.family: root.bodyFont
        font.pixelSize: 13
        font.bold: true
      }
    }

    Item {
      width: parent.width
      height: parent.height - 36

      Canvas {
        id: chart
        anchors.fill: parent
        anchors.rightMargin: 52

        onPaint: {
          var ctx = getContext("2d")
          var w = width
          var h = height
          ctx.clearRect(0, 0, w, h)
          if (w < 8 || h < 8) return

          var a = root.seriesA || []
          var b = root.seriesB || []
          var n = Math.max(a.length, b.length, 2)

          var lo = root.minValue
          var hi = root.maxValue
          if (!(hi > lo)) {
            hi = 0
            var i
            for (i = 0; i < a.length; i++) if (a[i] > hi) hi = a[i]
            for (i = 0; i < b.length; i++) if (b[i] > hi) hi = b[i]
            if (hi <= 0) hi = 1
            hi = hi * 1.18
            lo = 0
          }
          var span = Math.max(0.0001, hi - lo)

          function yOf(v) {
            return h - 1 - Math.max(0, Math.min(1, (v - lo) / span)) * (h - 2)
          }

          function css(c, alpha) {
            return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + alpha + ")"
          }

          function stroke(series, color, fillAlpha) {
            if (!series || series.length < 2) return
            var count = series.length
            var step = w / Math.max(1, n - 1)
            ctx.beginPath()
            ctx.moveTo(0, yOf(series[0] || 0))
            for (var s = 1; s < count; s++) ctx.lineTo(s * step, yOf(series[s] || 0))
            ctx.strokeStyle = css(color, 1)
            ctx.lineWidth = 2
            ctx.lineJoin = "round"
            ctx.stroke()
            ctx.lineTo((count - 1) * step, h)
            ctx.lineTo(0, h)
            ctx.closePath()
            ctx.fillStyle = css(color, fillAlpha)
            ctx.fill()
          }

          ctx.strokeStyle = "rgba(255,106,0,0.18)"
          ctx.lineWidth = 1
          ctx.beginPath()
          ctx.moveTo(0, 0); ctx.lineTo(w, 0)
          ctx.moveTo(0, h / 2); ctx.lineTo(w, h / 2)
          ctx.moveTo(0, h - 1); ctx.lineTo(w, h - 1)
          ctx.stroke()

          stroke(b, root.colorB, 0.16)
          stroke(a, root.colorA, 0.20)
        }
      }

      Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 50

        Text {
          width: parent.width
          height: parent.height / 3
          text: root.scaleHigh
          color: "#e8dcc8"
          font.family: root.bodyFont
          font.pixelSize: 11
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignTop
        }
        Item {
          width: parent.width
          height: parent.height / 3
        }
        Text {
          width: parent.width
          height: parent.height / 3
          text: root.scaleLow
          color: "#e8dcc8"
          font.family: root.bodyFont
          font.pixelSize: 11
          horizontalAlignment: Text.AlignRight
          verticalAlignment: Text.AlignBottom
        }
      }
    }

    Item {
      width: parent.width
      height: 12
      Text {
        anchors.left: parent.left
        text: "MIN  " + root.scaleLow
        color: "#9A8B7C"
        font.family: root.bodyFont
        font.pixelSize: 11
      }
      Text {
        anchors.right: parent.right
        text: "MAX  " + root.scaleHigh
        color: "#9A8B7C"
        font.family: root.bodyFont
        font.pixelSize: 11
      }
    }
  }
}
