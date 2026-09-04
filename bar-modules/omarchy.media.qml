import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

// MAGI media chip: play glyph, spectrum, and a title that stays on-screen.
BarWidget {
  id: root
  moduleName: "omarchy.media"

  readonly property var mediaService: bar && bar.shell ? bar.shell.firstPartyServiceFor("omarchy.media") : null
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property bool hasMedia: !!(activePlayer && (activePlayer.trackTitle || activePlayer.trackArtist || activePlayer.isPlaying))
  readonly property bool playing: !!(activePlayer && activePlayer.isPlaying)
  readonly property string title: {
    if (!activePlayer) return ""
    var name = String(activePlayer.trackTitle || "").trim()
    var artist = String(activePlayer.trackArtist || "").trim()
    if (name && artist) return name + "  ·  " + artist
    return name || artist || String(activePlayer.identity || "SIGNAL")
  }
  readonly property var cavaLevels: bar && bar.cavaLevels ? bar.cavaLevels : []
  readonly property real audioPeak: bar && bar.audioPeak ? bar.audioPeak : 0

  readonly property string displayFont: "Chakra Petch"
  readonly property color accent: "#FF6A00"
  readonly property color paper: "#F4F0E6"
  readonly property color muted: "#9A8B7C"
  readonly property int titleWidth: 148

  visible: hasMedia
  implicitWidth: hasMedia ? row.implicitWidth + 10 : 0
  implicitHeight: barSize

  function runMedia(action) {
    if (!mediaService || !activePlayer) return
    mediaService.runAction(action, false)
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 8

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.playing ? "▶" : "❚❚"
      color: root.playing ? root.accent : root.muted
      font.family: root.displayFont
      font.pixelSize: 11
      font.weight: 600
      width: 14
      horizontalAlignment: Text.AlignHCenter
    }

    MagiVisualizer {
      anchors.verticalCenter: parent.verticalCenter
      width: implicitWidth
      height: 16
      barCount: 8
      barWidth: 3
      gap: 2
      levels: root.cavaLevels
      peak: root.audioPeak
      playing: root.playing
      cavaActive: !!(root.bar && root.bar.cavaActive)
    }

    Item {
      id: titleClip
      width: root.titleWidth
      height: 16
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: titleText
        text: root.title
        color: root.paper
        font.family: root.displayFont
        font.pixelSize: 13
        font.weight: 600
        font.letterSpacing: 0.4
        verticalAlignment: Text.AlignVCenter
        height: parent.height
        x: 0
        onTextChanged: x = 0

        SequentialAnimation on x {
          running: titleText.implicitWidth > titleClip.width && root.hasMedia
          loops: Animation.Infinite
          PauseAnimation { duration: 1600 }
          NumberAnimation {
            to: titleClip.width - titleText.implicitWidth
            duration: Math.max(2800, (titleText.implicitWidth - titleClip.width) * 42)
            easing.type: Easing.InOutSine
          }
          PauseAnimation { duration: 900 }
          NumberAnimation {
            to: 0
            duration: 420
            easing.type: Easing.OutCubic
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.activePlayer) return
      if (mouse.button === Qt.MiddleButton) root.runMedia("next")
      else if (mouse.button === Qt.RightButton) {
        if (root.bar && typeof root.bar.toggleDash === "function") root.bar.toggleDash()
      } else {
        root.runMedia("playPause")
      }
    }
    onWheel: function(wheel) {
      if (!root.activePlayer) return
      if (wheel.angleDelta.y > 0) root.runMedia("previous")
      else root.runMedia("next")
    }
  }
}
