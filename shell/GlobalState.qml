// ┌──────────────────────────────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░█▀▀░█░░░█▀█░█▀▄░█▀█░█░░░░░█▀▀░▀█▀░█▀█░▀█▀░█▀▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░█░█░█░░░█░█░█▀▄░█▀█░█░░░░░▀▀█░░█░░█▀█░░█░░█▀▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░▀▀▀░▀▀▀░▀▀▀░▀▀░░▀░▀░▀▀▀░░░▀▀▀░░▀░░▀░▀░░▀░░▀▀▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀──────────────────────────────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>                             ├┤
// ││ Repo    : https://github.com/roosta/dotfiles                       ││
// ││ Site    : https://www.roosta.sh                                    ││
// ├┤ License : GNU General Public License v3                            ├┤
// ┆└────────────────────────────────────────────────────────────────────┘┆

pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.config

Singleton {
  id: root
  property bool launcherOpen: false
  property string launcherMonitorId: ""
  property string launcherMode: Config.defaultMode
  property bool calendarOpen: false
  property string calendarMonitorId: ""
  property bool wifiOpen: false
  property string wifiMonitorId: ""
  property bool overlayOpen: root.launcherOpen || root.trayMenuOpen || root.calendarOpen
    || root.wifiOpen
  property QsMenuHandle activeMenu: null
  property bool trayMenuOpen: false
  property int menuDirection: Qt.LeftToRight
  property int menuIndex: 0
  property string searchQuery: ""
  property int matchCount: 0
  property bool itemDrawerActive: false

  Timer {
    id: timer
    interval: Style.durations.small
    onTriggered: {
      root.launcherMonitorId = ""
      root.launcherMode = Config.defaultMode
      root.menuDirection = Qt.LeftToRight
      root.menuIndex = 0
      root.searchQuery = ""
    }
  }

  // The menu positions itself off the tray item that opened it, so unlike the
  // other overlays this one does not need to be told which monitor.
  function openTrayMenu(menu) {
    if (!menu) {
      console.error("No provided menu, cant open menu")
      return
    }
    root.activeMenu = menu
    trayMenuOpen = true
  }

  function closeTrayMenu() {
    root.activeMenu = null
    trayMenuOpen = false
  }

  function openLauncher({
    id = Config.primaryDisplay,
    mode = null,
    direction = Qt.LeftToRight,
    index = 0
  }) {
    launcherMonitorId = id
    if (index >= 0) {
      root.menuIndex = index
    }
    if (direction !== Qt.LeftToRight) {
      root.menuDirection = direction
    }
    if (mode) {
      root.launcherMode = mode
    }
    launcherOpen = true
  }

  // The calendar is a plain dropdown: unlike the launcher it takes no keyboard
  // focus and doesn't bump the exclusion zone, it just floats over the windows.
  function openCalendar(id = Config.primaryDisplay) {
    root.calendarMonitorId = id
    root.calendarOpen = true
  }

  function closeCalendar() {
    root.calendarOpen = false
  }

  function toggleCalendar(id = Config.primaryDisplay) {
    if (root.calendarOpen && root.calendarMonitorId === id) {
      closeCalendar()
    } else {
      openCalendar(id)
    }
  }

  // The wifi dropdown behaves like the calendar -- floats over the windows,
  // no exclusion zone -- except that it does want the keyboard once a password
  // field is open. shell.qml handles that with OnDemand focus.
  function openWifi(id = Config.primaryDisplay) {
    root.wifiMonitorId = id
    root.wifiOpen = true
  }

  function closeWifi() {
    root.wifiOpen = false
  }

  function toggleWifi(id = Config.primaryDisplay) {
    if (root.wifiOpen && root.wifiMonitorId === id) {
      closeWifi()
    } else {
      openWifi(id)
    }
  }

  function closeLauncher() {
    launcherOpen = false
    timer.restart()
  }

  function toggleLauncher({ id, mode = null, direction = Qt.LeftToRight, index = 0 }) {
    if (launcherOpen) {
      closeLauncher()
    } else {
      openLauncher({ id, mode, direction, index })
    }
  }
}
