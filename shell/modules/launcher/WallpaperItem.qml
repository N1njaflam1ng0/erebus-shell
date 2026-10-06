// Picker card for the launcher's wallpaper mode: a wide card whose preview
// fills everything above a short name/folder footer. Thumbnails are prebuilt
// JPEGs from erebus-wallpaper (a single frame for videos).

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.config
import qs.utils

Item {
  id: root
  property string name
  property string folder
  property string thumb
  property bool isVideo: false
  property bool isCurrentItem: ListView.isCurrentItem

  implicitHeight: parent?.height ?? 0
  implicitWidth: {
    const view = ListView.view
    if (!view || view.width <= 0) return 0
    const count = 5
    return (view.width - (count - 1) * view.spacing) / count
  }

  signal clicked()

  // Launcher.qml forwards drawer keys to whatever the current item is; a
  // wallpaper has no actions, so these are deliberately no-ops.
  signal openDrawer()
  signal closeDrawer()
  signal drawerNext()
  signal drawerPrev()
  signal drawerActivate()

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  states: [
    State {
      name: "hovered"
      when: mouseArea.containsMouse && !mouseArea.pressed
      PropertyChanges { card.color: Style.colors.gray1 }
    },
    State {
      name: "pressed"
      when: mouseArea.pressed
      PropertyChanges { card.border.color: Style.colors.white }
      PropertyChanges { card.color: Style.colors.gray2 }
    }
  ]

  MultiEffect {
    source: card
    anchors.fill: card
    shadowBlur: 1.0
    shadowEnabled: true
    shadowColor: Functions.transparentize("#000", 0.5)
    shadowVerticalOffset: 0
    shadowHorizontalOffset: 0
  }

  Rectangle {
    id: card
    anchors.fill: parent
    border.color: Style.colors.gray3
    border.width: Style.bar.borderWidth
    color: Style.colors.black

    Behavior on color {
      ColorAnimation {
        duration: Style.durations.tiny
        easing.type: Easing.InOutQuad
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.spacing.p2
      spacing: Style.spacing.p2

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Style.colors.gray1
        border.color: Style.colors.gray3
        border.width: 1
        clip: true

        Image {
          id: preview
          anchors.fill: parent
          anchors.margins: 1
          source: root.thumb
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          sourceSize.width: 480
          opacity: status === Image.Ready ? 1 : 0
          Behavior on opacity {
            NumberAnimation { duration: Style.durations.small }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: preview.status !== Image.Ready
          text: preview.status === Image.Error ? "no preview" : ""
          color: Style.colors.gray4
          font {
            family: Style.font.light
            pointSize: Style.font.small
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.p2

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.name || "(No name)"
            color: Style.colors.brightYellow
            font {
              family: Style.font.light
              pointSize: Style.font.large
            }
          }

          Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.folder
            color: Style.colors.brightBlue
            font {
              family: Style.font.light
              pointSize: Style.font.tiny
            }
          }
        }

        Text {
          visible: root.isVideo
          text: "▶"
          color: Style.colors.brightWhite
          font {
            family: Style.font.main
            pointSize: Style.font.normal
          }
        }
      }
    }
  }
}
