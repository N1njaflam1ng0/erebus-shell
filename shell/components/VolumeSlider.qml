// The bar's flat gradient volume slider, bound to one PipeWire node. Shared by
// AudioButton's inline slider and every row of the audio panel.
//
// The node has to be bound (a PwObjectTracker) for the volume to read back and
// to take writes -- AudioData tracks the default devices always, and the
// panel's lists while it is open.

import QtQuick
import QtQuick.Controls
import qs.config

Slider {
  id: root

  property var node: null
  // A muted node keeps its volume; the fill greys out so it doesn't look live.
  readonly property bool muted: root.node?.audio?.muted ?? false

  from: 0.0
  to: 1.0
  enabled: !!root.node?.audio
  value: root.node?.audio?.volume ?? 0
  onMoved: if (root.node?.audio) root.node.audio.volume = root.value

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  background: Rectangle {
    x: root.leftPadding
    y: root.topPadding + root.availableHeight / 2 - height / 2
    implicitWidth: 200
    implicitHeight: Style.spacing.p3
    width: root.availableWidth
    height: implicitHeight
    color: Style.colors.gray3

    Rectangle {
      width: root.visualPosition * parent.width
      height: parent.height
      visible: !root.muted
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 1; color: Style.colors.magenta }
        GradientStop { position: 0; color: Style.colors.blue }
      }
    }
    Rectangle {
      width: root.visualPosition * parent.width
      height: parent.height
      visible: root.muted
      color: Style.colors.gray5
    }
  }

  handle: Rectangle {
    x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
    y: root.topPadding + root.availableHeight / 2 - height / 2
    implicitWidth: Style.spacing.p4
    implicitHeight: Style.spacing.p3
    radius: 0
    color: {
      if (root.muted) return Style.colors.gray6
      return root.pressed ? Style.colors.brightMagenta : Style.colors.magenta
    }
  }
}
