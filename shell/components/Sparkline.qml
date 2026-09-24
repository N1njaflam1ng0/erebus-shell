// A minimal bar-chart sparkline: one column per sample, oldest on the left.
//
// Rectangles rather than a Canvas on purpose -- Canvas repaints its whole
// surface on every value change, and these tick once every couple of seconds on
// every monitor at once. The column widths are derived from the item's width, so
// the caller sizes it with Layout.preferredWidth like any other widget.

import QtQuick
import qs.config

Item {
  id: root

  // Newest sample last.
  property var values: []
  property int maxSamples: 60
  // 0 means autoscale to the largest sample in view -- what throughput wants,
  // since there is no meaningful ceiling on a link's rate. A fixed 1.0 is right
  // for the 0..1 ratios ResourceUsage publishes.
  property real maxValue: 1.0
  property color tint: Style.colors.accent
  property real gap: 1

  implicitWidth: Style.system.sparkWidth
  implicitHeight: Style.system.sparkHeight

  readonly property real ceiling: {
    if (root.maxValue > 0) return root.maxValue;
    const peak = Math.max(0, ...root.samples);
    return peak > 0 ? peak : 1;
  }

  // Left-padded with zeroes so the chart grows in from the right while history
  // fills up, instead of a handful of samples stretching across the whole width.
  readonly property var samples: {
    const tail = (root.values ?? []).slice(-root.maxSamples);
    return new Array(Math.max(0, root.maxSamples - tail.length)).fill(0).concat(tail);
  }

  readonly property real columnWidth: Math.max(
    1, (root.width - root.gap * (root.maxSamples - 1)) / root.maxSamples)

  Row {
    anchors.fill: parent
    spacing: root.gap

    Repeater {
      model: root.samples

      delegate: Item {
        required property real modelData
        width: root.columnWidth
        height: root.height

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          // A 1px floor so an idle stretch still reads as a baseline rather
          // than a hole in the chart.
          height: Math.max(1, Math.min(1, modelData / root.ceiling) * parent.height)
          color: root.tint
        }
      }
    }
  }
}
