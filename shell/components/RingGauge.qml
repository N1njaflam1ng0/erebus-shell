// A glyph inside a ring that fills clockwise from twelve o'clock with `value`.
//
// Shapes rather than a Canvas: a Canvas repaints its whole surface on every
// change, while this only re-tessellates one arc. The track is a full circle
// underneath, so an idle gauge still reads as a gauge.

import QtQuick
import QtQuick.Shapes
import qs.config

Item {
  id: root

  // 0.0 - 1.0; anything outside is clamped.
  property real value: 0
  property string glyph: ""
  property color tint: Style.colors.accent
  property color trackColor: Style.colors.gray3
  property int size: Style.bar.ringSize
  property real strokeWidth: Style.bar.ringStroke

  readonly property real clamped: Math.max(0, Math.min(1, Number.isFinite(root.value) ? root.value : 0))
  // Degrees of the value arc; eases toward 360 * clamped.
  property real sweep: 360 * root.clamped
  Behavior on sweep {
    NumberAnimation { duration: Style.durations.small; easing.type: Easing.OutCubic }
  }

  readonly property real radius: (root.size - root.strokeWidth) / 2

  implicitWidth: root.size
  implicitHeight: root.size

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.trackColor
      strokeWidth: root.strokeWidth
      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root.radius
        radiusY: root.radius
        startAngle: 0
        sweepAngle: 360
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.tint
      strokeWidth: root.strokeWidth
      capStyle: ShapePath.FlatCap
      PathAngleArc {
        centerX: root.size / 2
        centerY: root.size / 2
        radiusX: root.radius
        radiusY: root.radius
        startAngle: -90
        sweepAngle: root.sweep
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.tint
    font.family: Style.font.symbols
    font.pixelSize: Math.round(root.size * 0.45)
  }
}
