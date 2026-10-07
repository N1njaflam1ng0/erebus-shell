// Battery, via Quickshell.Services.UPower: the percentage inside a ring that
// empties as the battery drains, matching SysmonWidget's CPU and RAM rings.
// The time left is in a tooltip. Hides itself entirely on machines with no
// battery, so the same bar config works on pc and asusLaptop.

import QtQuick
import QtQuick.Controls
import Quickshell.Services.UPower
import qs.components
import qs.config

Item {
  id: root

  readonly property var dev: UPower.displayDevice

  // Bound to UPower; overridable so tests can feed values in.
  property bool present: dev?.isPresent ?? false
  property real pct: dev?.percentage ?? 0
  property bool charging: (dev?.state ?? UPowerDeviceState.Unknown) === UPowerDeviceState.Charging
  property bool full: (dev?.state ?? UPowerDeviceState.Unknown) === UPowerDeviceState.FullyCharged
  // Seconds; 0 when UPower has no estimate yet.
  property real timeToEmpty: dev?.timeToEmpty ?? 0
  property real timeToFull: dev?.timeToFull ?? 0

  readonly property color tint: {
    if (root.charging || root.full) return Style.colors.brightGreen;
    if (root.pct <= 0.15) return Style.colors.brightRed;
    if (root.pct <= 0.30) return Style.colors.brightYellow;
    return Style.colors.white;
  }

  readonly property string tipText: {
    const head = `Battery ${Math.round(root.pct * 100)}%`;
    if (root.full) return `${head} · full`;
    if (root.charging) {
      const t = root.formatDuration(root.timeToFull);
      return t ? `${head} · charging, full in ${t}` : `${head} · charging`;
    }
    const t = root.formatDuration(root.timeToEmpty);
    return t ? `${head} · ${t} left` : head;
  }

  // 4800 -> "1 h 20 min", 2700 -> "45 min"; "" under a minute or unknown.
  function formatDuration(seconds) {
    const minutes = Math.floor((Number.isFinite(seconds) ? seconds : 0) / 60);
    if (minutes < 1) return "";
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    if (h === 0) return `${m} min`;
    return m === 0 ? `${h} h` : `${h} h ${m} min`;
  }

  // Exposed for tests/battery.
  readonly property alias ring: ring

  visible: root.present
  implicitWidth: root.present ? ring.implicitWidth : 0
  implicitHeight: parent?.height ?? Style.bar.height

  RingGauge {
    id: ring
    anchors.verticalCenter: parent.verticalCenter
    value: root.pct
    text: `${Math.round(root.pct * 100)}`
    tint: root.tint

    HoverHandler { id: hover }

    ToolTip {
      id: tooltip
      font.family: Style.font.main
      delay: 600
      text: root.tipText
      visible: hover.hovered
      contentItem: Text {
        text: tooltip.text
        font: tooltip.font
        color: Style.colors.brightWhite
      }
      background: BorderRect {
        color: Style.colors.gray1
      }
    }
  }
}
