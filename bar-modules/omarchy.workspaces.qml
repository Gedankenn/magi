import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// EVA-styled workspace switcher for the bar. Orbitron CAIXA ALTA slots with
// NERV-ish square brackets: active workspace in accent orange, occupied in
// red, empty dimmed. Replaces the stock omarchy.workspaces look only; the
// click-to-focus behavior is preserved.
BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  readonly property string evaFont: "Chakra Petch"
  readonly property color accent: "#FF6A00"
  readonly property color red: "#C41E3A"
  readonly property color cream: "#e8dcc8"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.centerIn: parent
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      delegate: Item {
        id: slotItem
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        width: root.vertical ? root.barSize : Style.space(20)
        height: root.vertical ? Style.space(20) : Style.space(22)
        opacity: (occupied || focused) ? 1 : 0.45

        // Active: hollow accent-orange bracket with the id filled.
        Rectangle {
          anchors.fill: parent
          color: slotItem.focused ? "#33FF6A00" : "#00000000"
          border.color: slotItem.focused ? root.accent : (slotItem.occupied ? root.red : root.cream)
          border.width: slotItem.focused ? 2 : 1
          radius: 2
          visible: slotItem.focused

          Text {
            anchors.fill: parent
            textFormat: Text.PlainText
            text: String(modelData === 10 ? "0" : modelData)
            color: root.accent
            font.family: root.evaFont
            font.pixelSize: Style.font.caption
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }

        // Occupied / empty: slim red or cream tag, no fill.
        Rectangle {
          anchors.fill: parent
          color: "#00000000"
          border.color: slotItem.occupied ? root.red : root.cream
          border.width: 1
          radius: 1
          visible: !slotItem.focused

          Text {
            anchors.fill: parent
            textFormat: Text.PlainText
            text: String(modelData === 10 ? "0" : modelData)
            color: slotItem.occupied ? root.red : root.cream
            font.family: root.evaFont
            font.pixelSize: Style.font.caption
            font.weight: slotItem.occupied ? 500 : 400
            font.letterSpacing: 0.2
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(slotItem.modelData)
        }
      }
    }
  }
}
