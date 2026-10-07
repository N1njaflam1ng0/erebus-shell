// BatteryWidget: the ring and number follow the charge, the tints at the
// thresholds, the tooltip text, and hiding without a battery. The sandbox has
// no UPower, so every reading is fed in. Saves a screenshot to $OUT when set.
import QtQuick
import Quickshell
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

  function set(w, values) {
    w.present = values.present ?? true;
    w.pct = values.pct ?? 0.5;
    w.charging = values.charging ?? false;
    w.full = values.full ?? false;
    w.timeToEmpty = values.timeToEmpty ?? 0;
    w.timeToFull = values.timeToFull ?? 0;
  }

  function checkFormat() {
    const cases = [[4800, "1 h 20 min"], [2700, "45 min"], [7200, "2 h"], [59, ""], [0, ""], [NaN, ""]];
    cases.forEach(([s, want]) => {
      const got = battery.formatDuration(s);
      if (got !== want) root.fail(`formatDuration(${s}): ${got}`);
    });
  }

  readonly property var steps: [
    { what: "start", ready: () => true,
      act: () => {
        root.checkFormat();
        root.set(battery, { pct: 0.54, timeToEmpty: 4800 });
        root.set(low, { pct: 0.10 });
        root.set(warn, { pct: 0.30 });
        root.set(charging, { pct: 0.62, charging: true, timeToFull: 2700 });
        root.set(full, { pct: 1, full: true });
        root.set(absent, { present: false });
      } },
    { what: "rings settled", settle: 5, ready: () => Math.abs(battery.ring.sweep - 360 * 0.54) < 0.01,
      act: () => {
        if (Math.abs(battery.ring.clamped - 0.54) > 1e-9) root.fail("ring follows the charge");
        if (battery.ring.label.text !== "54") root.fail(`number: ${battery.ring.label.text}`);
        if (battery.ring.label.font.family !== Style.font.main) root.fail("number in the text face");
        if (!Qt.colorEqual(battery.tint, Style.colors.white)) root.fail("healthy is white");
        if (!Qt.colorEqual(warn.tint, Style.colors.brightYellow)) root.fail("30% is yellow");
        if (!Qt.colorEqual(low.tint, Style.colors.brightRed)) root.fail("10% is red");
        if (!Qt.colorEqual(charging.tint, Style.colors.brightGreen)) root.fail("charging is green");
        if (!Qt.colorEqual(full.tint, Style.colors.brightGreen)) root.fail("full is green");

        if (battery.tipText !== "Battery 54% · 1 h 20 min left") root.fail(`tip: ${battery.tipText}`);
        if (charging.tipText !== "Battery 62% · charging, full in 45 min") root.fail(`charging tip: ${charging.tipText}`);
        if (full.tipText !== "Battery 100% · full") root.fail(`full tip: ${full.tipText}`);
        if (low.tipText !== "Battery 10%") root.fail(`no estimate: ${low.tipText}`);

        const inner = full.ring.size - 2 * full.ring.strokeWidth;
        if (full.ring.label.implicitWidth >= inner) root.fail(`"100" overflows the ring: ${full.ring.label.implicitWidth} >= ${inner}`);
        if (absent.visible || absent.implicitWidth !== 0) root.fail("hidden without a battery");
        root.shot("battery");
      } },
    { what: "screenshot", settle: 3, ready: () => true, act: () => { console.log("PASS"); Qt.exit(0); } }
  ]

  FloatingWindow {
    implicitWidth: 360
    implicitHeight: 80
    color: "black"

    Row {
      id: content
      spacing: 12
      padding: 12
      height: 64

      BatteryWidget { id: battery }
      BatteryWidget { id: warn }
      BatteryWidget { id: low }
      BatteryWidget { id: charging }
      BatteryWidget { id: full }
      BatteryWidget { id: absent }
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
