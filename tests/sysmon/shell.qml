// RingGauge clamping and fill, and SysmonWidget's tints and tooltip text.
// Saves screenshots to $OUT when set.
import QtQuick
import Quickshell
import qs.components
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

  // [value, expected clamped]
  readonly property var cases: [[-0.2, 0], [0, 0], [0.5, 0.5], [1.4, 1], [NaN, 0]]

  function setRings() {
    root.cases.forEach(([v], i) => rings.itemAt(i).value = v);
  }

  function ringsSettled() {
    return root.cases.every(([, want], i) => Math.abs(rings.itemAt(i).sweep - 360 * want) < 0.01);
  }

  readonly property var steps: [
    { what: "rings built", ready: () => rings.count === root.cases.length, act: () => root.setRings() },
    { what: "rings filled", ready: () => root.ringsSettled(),
      act: () => {
        root.cases.forEach(([v, want], i) => {
          if (rings.itemAt(i).clamped !== want) root.fail(`clamp ${v}: got ${rings.itemAt(i).clamped}`);
        });
        sysmon.cpu = 0.42;
        sysmon.memory = 0.4;
      } },
    { what: "calm readings", settle: 3, ready: () => true,
      act: () => {
        if (sysmon.cpuText !== "CPU 42%") root.fail(`cpu text: ${sysmon.cpuText}`);
        if (!/^RAM \d+\.\d \/ \d+\.\d GB \(40%\)$/.test(sysmon.memoryText)) root.fail(`ram text: ${sysmon.memoryText}`);
        if (sysmon.cpuRing.tint === sysmon.cpuRing.trackColor) root.fail("cpu tint");
        if (Math.abs(sysmon.cpuRing.clamped - 0.42) > 1e-9) root.fail("cpu ring follows the reading");
        if (sysmon.cpuRing.label.font.family !== Style.font.symbols) root.fail("glyph rings keep the symbols face");
        if (sysmon.cpuRing.label.text !== sysmon.cpuRing.glyph) root.fail("glyph ring shows its glyph");
        root.calmCpu = sysmon.cpuTint;
        root.calmMemory = sysmon.memoryTint;
        root.shot("sysmon-calm");
        sysmon.cpu = 0.81;
        sysmon.memory = 0.91;
      } },
    { what: "busy readings", settle: 3, ready: () => true,
      act: () => {
        if (Qt.colorEqual(sysmon.cpuTint, root.calmCpu)) root.fail("cpu turns red past 80%");
        if (Qt.colorEqual(sysmon.memoryTint, root.calmMemory)) root.fail("ram turns red past 90%");
        if (!Qt.colorEqual(sysmon.cpuTint, sysmon.memoryTint)) root.fail("both alarms share a colour");
        sysmon.cpu = 0.8;
        sysmon.memory = 0.9;
      } },
    { what: "thresholds inclusive of calm", settle: 1, ready: () => true,
      act: () => {
        if (!Qt.colorEqual(sysmon.cpuTint, root.calmCpu)) root.fail("80% exactly is calm");
        if (!Qt.colorEqual(sysmon.memoryTint, root.calmMemory)) root.fail("90% exactly is calm");
        root.shot("rings");
      } },
    { what: "screenshot", settle: 3, ready: () => true, act: () => { console.log("PASS"); Qt.exit(0); } }
  ]

  property color calmCpu
  property color calmMemory

  FloatingWindow {
    implicitWidth: 400
    implicitHeight: 120
    color: "black"

    Column {
      id: content
      spacing: 12
      padding: 12

      Row {
        spacing: 12
        Repeater {
          id: rings
          model: root.cases.length
          RingGauge { glyph: "󰍛" }
        }
      }

      Item {
        width: 200
        height: 40
        SysmonWidget { id: sysmon }
      }
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
