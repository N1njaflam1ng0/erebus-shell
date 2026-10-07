// Notifications: the launcher's "Clear all" button against a seeded history.
// Saves screenshots to $OUT when set.
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.launcher

ShellRoot {
  id: root

  property int step: 0
  property int waited: 0

  function fail(what) {
    console.error(`FAIL ${what}`);
    Qt.exit(1);
  }

  function shot(name) {
    if (Quickshell.env("OUT")) launcher.grabToImage(r => r.saveToFile(`${Quickshell.env("OUT")}/${name}.png`));
  }

  // What Notifications saved, read back independently of the service.
  FileView {
    id: saved
    path: `${Quickshell.env("XDG_CACHE_HOME")}/erebus/notifications.json`
    watchChanges: true
    onFileChanged: reload()
  }

  function savedList() {
    try { return JSON.parse(saved.text()) } catch (e) { return null }
  }

  readonly property var button: launcher.clearAllButton

  readonly property var steps: [
    { what: "history loaded", ready: () => Notifications.list.length === 3,
      act: () => {
        if (root.button.visible) root.fail("button hidden while the launcher is closed");
        Notifications.unread = 2;
        GlobalState.openLauncher({ id: "TEST", mode: "notifications" });
      } },
    { what: "button shown", settle: 5, ready: () => root.button.visible,
      act: () => {
        root.shot("notifications");
        root.button.activated();
      } },
    { what: "cleared", ready: () => Notifications.list.length === 0 && root.savedList()?.length === 0,
      act: () => {
        if (Notifications.unread !== 0) root.fail("unread reset");
        if (!GlobalState.launcherOpen) root.fail("launcher stays open");
      } },
    { what: "button hidden", settle: 5, ready: () => !root.button.visible,
      act: () => {
        root.shot("cleared");
        GlobalState.launcherMode = "apps";
      } },
    { what: "apps mode", ready: () => GlobalState.launcherMode === "apps",
      act: () => {
        if (root.button.visible) root.fail("button only in notifications mode");
        console.log("PASS");
        Qt.exit(0);
      } }
  ]

  FloatingWindow {
    implicitWidth: 1440
    implicitHeight: 400
    color: "black"

    Launcher {
      id: launcher
      monitorId: "TEST"
    }
  }

  Timer {
    interval: 100
    repeat: true
    running: true
    onTriggered: {
      const s = root.steps[root.step];
      if (s.ready() && root.waited >= (s.settle ?? 0)) {
        root.waited = 0;
        root.step++;
        s.act();
      } else if (++root.waited > 100) {
        root.fail(`timed out waiting for: ${s.what}`);
      }
    }
  }
}
