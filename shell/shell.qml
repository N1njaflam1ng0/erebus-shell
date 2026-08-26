// ┌──────────────────────────────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░█▀▄░▀█▀░▀█▀░█░█░█▀█░█░░░░░█▀▀░█░█░█▀▀░█░░░█░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░█▀▄░░█░░░█░░█░█░█▀█░█░░░░░▀▀█░█▀█░█▀▀░█░░░█░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀░▀▀▀░░░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀──────────────────────────────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>                             ├┤
// ││ Repo    : https://github.com/roosta/dotfiles                       ││
// ││ Site    : https://www.roosta.sh                                    ││
// ├┤ License : GNU General Public License v3                            ├┤
// ┆└────────────────────────────────────────────────────────────────────┘┆
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

pragma ComponentBehavior: Bound
import Quickshell
import qs.modules.bar
import qs.modules.launcher
import qs.modules.calendar
import qs.modules.tray
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.utils
import qs.config
import qs.services
import qs

ShellRoot {
  Variants {
    model: Quickshell.screens
    delegate: Scope {
      id: scope
      required property ShellScreen modelData
      property string monitorId: modelData?.name ?? ""
      readonly property HyprlandMonitor monitor: Hyprland
        .monitorFor(modelData)
      readonly property int activeWorkspaceId: monitor?.activeWorkspace?.id ?? 1
      property var windows: HyprlandData.windowsByWorkspace[activeWorkspaceId] ?? []

      NamedPanel {
        id: exclusion
        WlrLayershell.layer: WlrLayer.Bottom
        name: "exclusion"
        screen: scope.modelData
        anchors.top: true
        anchors.left: true
        anchors.right: true

        // One commit on open, one on close — Hyprland animates the windows.
        // Animating this would relayout every window on the monitor per frame.
        exclusiveZone: GlobalState.launcherOpen && GlobalState.launcherMonitorId === scope.monitorId
          ? Style.bar.height + Style.launcher.height
          : Style.bar.height
      }

      NamedPanel {
        id: main
        name: "main"
        screen: scope.modelData

        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        // OnDemand, not Exclusive: the calendar's quick-add field can be
        // clicked into, but opening the panel doesn't steal the keyboard.
        WlrLayershell.keyboardFocus: GlobalState.launcherOpen || GlobalState.calendarOpen
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

        HyprlandFocusGrab {
          id: grab
          windows: [main]
          active: (GlobalState.launcherOpen && GlobalState.launcherMonitorId === scope.monitorId)
            || (GlobalState.calendarOpen && GlobalState.calendarMonitorId === scope.monitorId)
          // Deliberately empty, for both overlays. Hyprland fires `cleared`
          // immediately after the grab activates, so closing from here shuts
          // the panel the moment it opens. Click-outside is handled instead by
          // the MouseArea on `content` below: this window is fullscreen and
          // holds the grab, so every click is "inside" it and reaches that.
          onCleared: {
          }
        }

        // Pass through clicks unless overlay is open
        mask: Region {
          id: mask
          x: 0
          y: 0
          width: main.width
          height: main.height

          intersection: {
            if (GlobalState.overlayOpen) {
              Intersection.Combine
            } else {
              Intersection.Xor
            }
          }
          regions: [

            // Lets the bar be usable when overlay is open
            Region {
              x: bar.x
              y: bar.y
              width: bar.width
              height: bar.height
              intersection: {
                if (GlobalState.overlayOpen) {
                  Intersection.Combine
                } else {
                  Intersection.Subtract
                }
              }
            },

            // Lets the toast message be usable with overlay open
            Region {
              x: toast.x
              y: toast.y
              width: toast.implicitWidth
              height: toast.implicitHeight
              intersection: {
                if (Notifications.popupList.length) {
                  Intersection.Subtract
                } else {
                  Intersection.Combine
                }
              }

            }
          ]
        }

        anchors {
          bottom: true
          left: true
          right: true
          top: true
        }
        Rectangle {
          id: content
          color: "transparent"
          anchors.fill: parent
          transitions: [
            Transition {
              ColorAnimation {
                duration: 300
                easing.type: Easing.OutQuad
              }
            }
          ]
          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (GlobalState.launcherOpen) { GlobalState.closeLauncher() }
              if (GlobalState.trayMenuOpen) { GlobalState.closeTrayMenu() }
              if (GlobalState.calendarOpen) { GlobalState.closeCalendar() }
            }
          }
          states: [
            State {
              name: "open"
              when: (GlobalState.launcherOpen || GlobalState.trayMenuOpen)
                && scope.windows.length > 0
              PropertyChanges { content.color: Functions.transparentize("#000", 0.7) }
            }
          ]

        }
        Bar {
          id: bar
          monitorId: scope.monitorId
          onDecrementCurrentIndex: launcher.decrementCurrentIndex()
          onIncrementCurrentIndex: launcher.incrementCurrentIndex()
          onOpenDrawer: launcher.openDrawer()
          onCloseDrawer: launcher.closeDrawer()
          onDrawerNext: launcher.drawerNext()
          onDrawerPrev: launcher.drawerPrev()
          onDrawerActivate: launcher.drawerActivate()
          onAccepted: launcher.accepted()
        }

        Launcher {
          id: launcher
          monitorId: scope.monitorId
        }

        CalendarPanel {
          id: calendarPanel
          monitorId: scope.monitorId
        }

        Osd {
          id: osd
          monitorId: scope.monitorId
        }

        Toast {
          id: toast
          monitorId: scope.monitorId
          menuRect: trayMenu.item ? trayMenu.item.menuRect : Qt.rect(0,0,0,0)

        }

        Loader {
          id: trayMenu
          anchors.fill: parent
          active: GlobalState.trayMenuOpen

          sourceComponent: TrayMenu {
            Component.onCompleted: this.open();
            trayItemMenuHandle: GlobalState.activeMenu
            onMenuOpened: (window) => {};
            onMenuClosed: GlobalState.closeTrayMenu()
            monitorId: scope.monitorId
          }
        }
      }
    }
  }
}
