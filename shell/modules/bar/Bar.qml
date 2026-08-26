// ┌───────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░░░░░░█▀▄░█▀█░█▀▄░░░░░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░░░░░░█▀▄░█▀█░█▀▄░░░░░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░░░░░░▀▀░░▀░▀░▀░▀░░░░░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀───────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>      ├┤
// ││ Repo    : https://github.com/roosta/dotfiles││
// ││ Site    : https://www.roosta.sh             ││
// ├┤ License : GNU General Public License v3     ├┤
// ┆└─────────────────────────────────────────────┘┆

import QtQuick
import qs.components
import qs.services
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
pragma ComponentBehavior: Bound

Item {
  id: root
  required property string monitorId

  z: 1
  implicitHeight: Style.bar.height

  signal decrementCurrentIndex()
  signal incrementCurrentIndex()
  signal drawerNext()
  signal drawerPrev()
  signal accepted()
  signal openDrawer()
  signal closeDrawer()
  signal drawerActivate()

  anchors {
    top: parent.top
    left: parent.left
    right: parent.right
  }

  BorderRect {
    id: barContent
    color: Style.colors.black
    borderColor: Style.colors.gray3
    bottomBorder: 1
    anchors {
      right: parent.right
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    Rectangle {
      anchors.fill: parent
      color: "transparent"

      Loader {
        id: barLoader
        anchors.fill: parent
        sourceComponent: primaryBar
      }}
    }
    Component {
      id: primaryBar
      Rectangle {
        color: "transparent"
        anchors.fill: parent

        RowLayout {
          anchors.fill: parent
          spacing: 0
          Rectangle {
            id: leftSection
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            RowLayout {
              spacing: Style.spacing.p1
              anchors.left: parent.left
              anchors.fill: parent
              LauncherButton {
                monitorId: root.monitorId
                onDecrementCurrentIndex: root.decrementCurrentIndex()
                onIncrementCurrentIndex: root.incrementCurrentIndex()
                onOpenDrawer: root.openDrawer()
                onCloseDrawer: root.closeDrawer()
                onDrawerNext: root.drawerNext()
                onDrawerActivate: root.drawerActivate()
                onDrawerPrev: root.drawerPrev()
                onAccepted: root.accepted()
              }
              Separator {}
              Loader {
                Layout.fillHeight: true
                Layout.fillWidth: true
                active: LauncherData.appsData.length > 0
                sourceComponent: Context { }
              }

              MediaWidget { }
            }
          }
          Rectangle {
            id: centerSection
            color: "transparent"
            Layout.fillHeight: true
            Layout.fillWidth: true
            // Layout.alignment: Qt.AlignHCenter
            RowLayout {
              spacing: Style.spacing.p1
              anchors.centerIn: parent
              ShiftButton { direction: -1; monitorId: root.monitorId }
              Workspaces { monitorId: root.monitorId }
              ShiftButton { direction: 1; monitorId: root.monitorId }
            }
          }
          Rectangle {
            id: rightSection
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: "transparent"
            RowLayout {
              spacing: Style.spacing.p1
              anchors.right: parent.right
              // anchors.rightMargin: Style.spacing.p1
              // anchors.fill: parent
              SysmonWidget { }
              NetworkWidget { }
              BluetoothWidget { }
              BatteryWidget { }
              Separator {}
              Clock { monitorId: root.monitorId }
              Separator {}
              AlertsIndicator { monitorId: root.monitorId }
              KeyboardButton { monitorId: root.monitorId }
              AudioButton { monitorId: root.monitorId }
              TrayButton { monitorId: root.monitorId }
              Separator {}
              NotificationButton { monitorId: root.monitorId }
            }
          }
        }
      }
    }
  }
