// NetworkWidget: the network name lights up with the icon while the Wi-Fi
// panel is open, and both go back afterwards. The sandbox has no
// NetworkManager, so the name is fed in. Saves screenshots to $OUT when set.
import QtQuick
import Quickshell
import qs
import qs.config
import qs.modules.bar

ShellRoot {
  id: root

  property int step: 0
  property int waited: 0

  function fail(what) {
    console.error(`FAIL ${what}`);
    Qt.exit(1);
  }

  function shot(name) {
    if (Quickshell.env("OUT")) content.grabToImage(r => r.saveToFile(`${Quickshell.env("OUT")}/${name}.png`));
  }

  readonly property bool lit: Qt.colorEqual(network.icon.color, Style.colors.accent)
    && Qt.colorEqual(network.labelText.color, Style.colors.accent)

  readonly property var steps: [
    { what: "start", ready: () => true,
      act: () => {
        network.label = "HomeNet";
        if (network.highlighted) root.fail("calm while closed");
        if (!Qt.colorEqual(network.labelText.color, Style.colors.white)) root.fail("name is white at rest");
        GlobalState.openWifi("TEST");
      } },
    { what: "lit", ready: () => root.lit,
      act: () => {
        if (!network.labelText.visible || network.labelText.text !== "HomeNet") root.fail("name shown");
        root.shot("network-open");
        GlobalState.openWifi("OTHER");
      } },
    { what: "another monitor's panel leaves it calm", settle: 3,
      ready: () => Qt.colorEqual(network.labelText.color, Style.colors.white),
      act: () => {
        if (Qt.colorEqual(network.icon.color, Style.colors.accent)) root.fail("icon calm too");
        GlobalState.openWifi("TEST");
      } },
    { what: "lit again", ready: () => root.lit, act: () => GlobalState.closeWifi() },
    { what: "back to rest", settle: 3, ready: () => Qt.colorEqual(network.labelText.color, Style.colors.white),
      act: () => {
        if (Qt.colorEqual(network.icon.color, Style.colors.accent)) root.fail("icon back to rest");
        root.shot("network-closed");
      } },
    { what: "screenshot", settle: 3, ready: () => true, act: () => { console.log("PASS"); Qt.exit(0); } }
  ]

  FloatingWindow {
    implicitWidth: 240
    implicitHeight: 60
    color: "black"

    Item {
      id: content
      width: 240
      height: 40
      NetworkWidget { id: network; monitorId: "TEST"; x: 12 }
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
