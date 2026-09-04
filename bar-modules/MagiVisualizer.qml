import QtQuick

// MAGI spectrum bars. Prefers live cava levels from the bar; otherwise
// builds a bass-weighted EQ from the Pipewire peak so it still moves.
Item {
  id: root

  property var levels: []
  property real peak: 0
  property bool playing: false
  property bool cavaActive: false
  property int barCount: 12
  property int barWidth: 3
  property int gap: 2
  property color fill: "#FF6A00"
  property color hot: "#A8FF3E"

  property var display: []

  readonly property int computedBarWidth: {
    var n = barCount
    if (n <= 0) return barWidth
    if (width > 0) return Math.max(1, Math.floor((width - (n - 1) * gap) / n))
    return barWidth
  }

  implicitWidth: barCount * (barWidth + gap) - gap
  implicitHeight: 18

  function tick() {
    var cava = levels || []
    var live = cavaActive && cava.length > 0
    if (!live) {
      for (var i = 0; i < cava.length; i++) {
        if ((cava[i] || 0) > 0.02) { live = true; break }
      }
    }

    var next = []
    var t = Date.now() / 1000
    var bass = Math.pow(Math.max(0, Math.min(1, peak)), 0.62)

    for (var b = 0; b < barCount; b++) {
      var target = 0.05
      if (live) {
        var idx = Math.min(cava.length - 1, Math.floor(b * cava.length / barCount))
        target = Math.max(0, Math.min(1, cava[idx] || 0))
      } else if (playing) {
        var band = Math.exp(-b * 0.16)
        var wobble = 0.5 + 0.5 * Math.sin(t * (2.1 + b * 0.62) + b * 0.85)
        var treble = Math.pow(bass, 0.35 + b * 0.04)
        target = Math.max(0.07, Math.min(1, (0.35 + bass * 0.9) * band * wobble * (0.45 + treble)))
      }
      var cur = display.length > b ? display[b] : 0
      var k = target > cur ? 0.48 : 0.16
      next.push(cur + (target - cur) * k)
    }
    display = next
  }

  Timer {
    interval: 33
    running: root.visible && (root.playing || root.cavaActive)
    repeat: true
    onTriggered: root.tick()
  }

  Row {
    anchors.fill: parent
    spacing: root.gap

    Repeater {
      model: root.barCount

      Item {
        required property int index
        width: root.computedBarWidth
        height: parent.height

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Math.max(2, parent.height * (root.display[index] || 0))
          color: (root.display[index] || 0) > 0.78 ? root.hot : root.fill
        }
      }
    }
  }
}
