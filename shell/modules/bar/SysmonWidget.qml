// CPU and RAM usage as rings that fill up, from the ResourceUsage service.
// The numbers live in a tooltip; the rings are a constant size, so the bar
// never reflows as the readings change.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

Rectangle {
  id: root
  implicitWidth: childrenRect.width
  implicitHeight: parent?.height ?? Style.bar.height
  color: "transparent"

  // 0.0 - 1.0. Bound to the service; overridable so tests can feed values in.
  property real cpu: ResourceUsage.cpuUsage
  property real memory: ResourceUsage.memoryUsedPercentage

  readonly property color cpuTint: root.cpu > 0.8 ? Style.colors.brightRed : Style.colors.brightBlue
  readonly property color memoryTint: root.memory > 0.9 ? Style.colors.brightRed : Style.colors.brightGreen

  readonly property string cpuText: `CPU ${Math.round(root.cpu * 100)}%`
  readonly property string memoryText:
    `RAM ${ResourceUsage.memoryUsedGb} / ${ResourceUsage.memoryTotalGb} GB (${Math.round(root.memory * 100)}%)`

  // Exposed for tests/sysmon.
  readonly property alias cpuRing: cpuRing
  readonly property alias memoryRing: memoryRing

  component Stat: RingGauge {
    id: stat
    required property string tip

    HoverHandler { id: hover }

    ToolTip {
      id: tooltip
      font.family: Style.font.main
      delay: 600
      text: stat.tip
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

  RowLayout {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.p1

    Stat {
      id: cpuRing
      glyph: "󰻠"
      value: root.cpu
      tint: root.cpuTint
      tip: root.cpuText
    }
    Stat {
      id: memoryRing
      glyph: "󰍛"
      value: root.memory
      tint: root.memoryTint
      tip: root.memoryText
    }
  }
}
