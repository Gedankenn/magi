import QtQuick

// Compact MAGI month grid. Used by the dashboard, lock screen, and clock popup.
Item {
  id: root

  property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()
  property bool followToday: true
  property int weekStart: 1
  property color paper: "#F4F0E6"
  property color muted: "#9A8B7C"
  property color accent: "#FF6A00"
  property color blood: "#C41E3A"
  property string displayFont: "Chakra Petch"
  property string fontFamily: "Nimbus Sans Narrow"
  property bool interactive: true
  property int cellSize: 28

  readonly property date viewDate: new Date(viewYear, viewMonth, 1)
  readonly property bool viewingCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()
  readonly property var weekdays: weekdayOrder()
  readonly property var weeks: monthGrid()
  readonly property string todayKey: dateKey(today.getFullYear(), today.getMonth(), today.getDate())

  function pad2(n) {
    return (n < 10 ? "0" : "") + n
  }

  function dateKey(year, month, day) {
    return year + "-" + pad2(month + 1) + "-" + pad2(day)
  }

  function weekdayOrder() {
    var out = []
    for (var i = 0; i < 7; i++) out.push((weekStart + i) % 7)
    return out
  }

  function weekdayLabel(day) {
    return ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][day]
  }

  function monthGrid() {
    var leading = (new Date(viewYear, viewMonth, 1).getDay() - weekStart + 7) % 7
    var cursor = new Date(viewYear, viewMonth, 1 - leading)
    var rows = []
    for (var w = 0; w < 6; w++) {
      var days = []
      for (var d = 0; d < 7; d++) {
        days.push({
          day: cursor.getDate(),
          inMonth: cursor.getMonth() === viewMonth && cursor.getFullYear() === viewYear,
          today: dateKey(cursor.getFullYear(), cursor.getMonth(), cursor.getDate()) === todayKey,
          weekend: cursor.getDay() === 0 || cursor.getDay() === 6
        })
        cursor.setDate(cursor.getDate() + 1)
      }
      rows.push(days)
    }
    return rows
  }

  function goToToday() {
    followToday = true
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  function moveMonth(delta) {
    followToday = false
    var next = new Date(viewYear, viewMonth + delta, 1)
    viewYear = next.getFullYear()
    viewMonth = next.getMonth()
  }

  onTodayChanged: {
    if (!followToday) return
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  implicitWidth: grid.implicitWidth
  implicitHeight: col.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Column {
    id: col
    spacing: 8
    width: grid.implicitWidth

    Item {
      width: parent.width
      height: 22

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.interactive
        text: "‹"
        color: prevHit.containsMouse ? root.accent : root.muted
        font.family: root.displayFont
        font.pixelSize: 18
        font.weight: 600
        MouseArea {
          id: prevHit
          anchors.fill: parent
          anchors.margins: -6
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.moveMonth(-1)
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDate(root.viewDate, "MMM yyyy").toUpperCase()
        color: root.paper
        font.family: root.displayFont
        font.pixelSize: 13
        font.letterSpacing: 1.6
        font.weight: 600
        MouseArea {
          anchors.fill: parent
          enabled: root.interactive && !root.viewingCurrentMonth
          cursorShape: Qt.PointingHandCursor
          onClicked: root.goToToday()
        }
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.interactive
        text: "›"
        color: nextHit.containsMouse ? root.accent : root.muted
        font.family: root.displayFont
        font.pixelSize: 18
        font.weight: 600
        MouseArea {
          id: nextHit
          anchors.fill: parent
          anchors.margins: -6
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.moveMonth(1)
        }
      }
    }

    Column {
      id: grid
      spacing: 2

      Row {
        spacing: 2
        Repeater {
          model: root.weekdays
          Text {
            required property var modelData
            width: root.cellSize
            height: 14
            text: root.weekdayLabel(modelData)
            color: root.muted
            font.family: root.displayFont
            font.pixelSize: 9
            font.letterSpacing: 0.8
            font.weight: 600
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
      }

      Repeater {
        model: root.weeks
        Row {
          required property var modelData
          spacing: 2
          Repeater {
            model: modelData
            Rectangle {
              required property var modelData
              width: root.cellSize
              height: root.cellSize
              color: modelData.today ? Qt.rgba(1, 0.42, 0, 0.16) : "transparent"
              border.width: modelData.today ? 1 : 0
              border.color: root.accent
              Text {
                anchors.centerIn: parent
                text: modelData.day
                color: modelData.today
                  ? root.accent
                  : (modelData.inMonth
                    ? (modelData.weekend ? root.blood : root.paper)
                    : Qt.rgba(0.96, 0.94, 0.9, 0.22))
                font.family: root.fontFamily
                font.pixelSize: 11
                font.bold: modelData.today
              }
            }
          }
        }
      }
    }
  }

  WheelHandler {
    enabled: root.interactive
    onWheel: function(event) {
      if (event.angleDelta.y === 0) return
      root.moveMonth(event.angleDelta.y > 0 ? -1 : 1)
    }
  }
}
