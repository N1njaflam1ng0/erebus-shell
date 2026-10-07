// Slim strip above the notification list: how many there are on the left, and
// a flat "Clear all" on the right that only turns red under the pointer. Kept
// quiet on purpose; a solid button drew the eye away from the notifications.

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

BorderRect {
  id: root

  property int count: 0
  signal activated()

  // Exposed for tests/notifications.
  readonly property alias countText: countText
  readonly property alias clearButton: clearButton

  implicitHeight: Style.launcher.headerHeight
  bottomBorder: Style.bar.borderWidth
  borderColor: Style.colors.gray2

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Style.spacing.p3
    anchors.rightMargin: Style.spacing.p3
    spacing: Style.spacing.p2

    Text {
      id: countText
      text: root.count === 1 ? "1 notification" : `${root.count} notifications`
      color: Style.colors.gray6
      font.family: Style.font.main
      font.pointSize: Style.font.small
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
    }

    Item {
      id: clearButton
      readonly property bool hovered: area.containsMouse
      readonly property color tint: hovered ? Style.colors.brightRed : Style.colors.white

      implicitWidth: label.implicitWidth
      implicitHeight: root.implicitHeight
      Layout.alignment: Qt.AlignVCenter

      Row {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.p1

        Text {
          text: "\u{F039F}"
          color: clearButton.tint
          font.family: Style.font.symbols
          font.pointSize: Style.font.small
          anchors.verticalCenter: parent.verticalCenter
          Behavior on color {
            ColorAnimation { duration: Style.durations.hover; easing.type: Easing.OutQuad }
          }
        }
        Text {
          text: "Clear all"
          color: clearButton.tint
          font.family: Style.font.main
          font.pointSize: Style.font.small
          anchors.verticalCenter: parent.verticalCenter
          Behavior on color {
            ColorAnimation { duration: Style.durations.hover; easing.type: Easing.OutQuad }
          }
        }
      }

      MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
      }
    }
  }
}
