// Audio dropdown, opened by left-clicking the bar's audio button: output and
// microphone volume and mute, the device pickers for both, and a volume slider
// per application that is playing.
//
// Same sliding-Item idiom as modules/system/SysPanel.qml: it lives inside
// shell.qml's fullscreen "main" panel and drops out of the top-right corner,
// which it shares with the calendar, wifi and system panels (GlobalState closes
// the others). It sizes to its contents, up to Style.audio.maxHeight, past
// which it scrolls.
//
// Everything PipeWire is in services/AudioData.qml, since shell.qml builds one
// of these per monitor. Glyphs are written as escapes: Nerd Font codepoints are
// invisible in most editors and easy to lose.

pragma ComponentBehavior: Bound

import qs
import qs.components
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  required property string monitorId

  anchors.top: parent.top
  anchors.topMargin: Style.bar.height
  anchors.right: parent.right
  anchors.rightMargin: Style.spacing.p1

  readonly property real panelHeight: Math.min(
    content.implicitHeight + Style.spacing.p2 * 2, Style.audio.maxHeight)

  implicitWidth: Style.audio.width
  implicitHeight: root.panelHeight

  // The slide happens inside these bounds.
  clip: true

  readonly property bool active: GlobalState.audioOpen
    && GlobalState.audioMonitorId === root.monitorId

  // Only render while on-screen or mid-transition.
  visible: panel.y > -root.panelHeight

  // Exposed for tests/audio.
  readonly property alias noOutputs: noOutputs
  readonly property alias noInputs: noInputs
  readonly property alias nothingPlaying: nothingPlaying
  readonly property real slideY: panel.y

  readonly property string speakerMutedGlyph: "\u{EB24}"
  readonly property string micGlyph: "\u{EC1C}"
  readonly property string micMutedGlyph: "\u{F036D}"
  readonly property string appsGlyph: "\u{F003B}"
  readonly property string checkGlyph: "\u{F012C}"

  // ── Local building blocks ──────────────────────────────────────────────

  component SectionTitle: RowLayout {
    id: title
    required property string glyph
    required property string text
    spacing: Style.spacing.p1
    Layout.fillWidth: true
    Layout.topMargin: Style.spacing.p1

    Text {
      text: title.glyph
      color: Style.colors.gray6
      font.family: Style.font.symbols
      font.pointSize: Style.font.small
      Layout.alignment: Qt.AlignVCenter
    }
    Text {
      text: title.text
      color: Style.colors.brightWhite
      font.family: Style.font.main
      font.pointSize: Style.font.normal
      Layout.alignment: Qt.AlignVCenter
    }
  }

  component Hint: Text {
    color: Style.colors.gray6
    font.family: Style.font.main
    font.pointSize: Style.font.small
    Layout.fillWidth: true
    Layout.leftMargin: Style.spacing.p1
    Layout.preferredHeight: Style.audio.rowHeight
    verticalAlignment: Text.AlignVCenter
  }

  // Mute toggle, slider and percentage for one node.
  component VolumeRow: RowLayout {
    id: row
    required property var node
    required property string glyph
    required property string mutedGlyph
    property string label: ""

    readonly property bool muted: row.node?.audio?.muted ?? false

    Layout.fillWidth: true
    Layout.preferredHeight: Style.audio.rowHeight
    spacing: Style.spacing.p1

    Rectangle {
      implicitWidth: Style.audio.rowHeight
      implicitHeight: Style.audio.rowHeight
      color: muteArea.containsMouse ? Style.colors.gray2 : "transparent"
      Behavior on color {
        ColorAnimation { duration: Style.durations.hover; easing.type: Easing.OutQuad }
      }
      Text {
        anchors.centerIn: parent
        text: row.muted ? row.mutedGlyph : row.glyph
        color: row.muted ? Style.colors.brightRed : Style.colors.white
        font.family: Style.font.symbols
        font.pixelSize: Style.font.size3
      }
      MouseArea {
        id: muteArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AudioData.toggleNodeMute(row.node)
      }
    }
    Text {
      visible: row.label !== ""
      text: row.label
      elide: Text.ElideRight
      color: Style.colors.white
      font.family: Style.font.main
      font.pointSize: Style.font.small
      Layout.preferredWidth: 96 * Config.scale
      Layout.alignment: Qt.AlignVCenter
    }
    VolumeSlider {
      node: row.node
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
    }
    Text {
      text: `${Math.round((row.node?.audio?.volume ?? 0) * 100)}%`
      color: Style.colors.brightWhite
      horizontalAlignment: Text.AlignRight
      font.family: Style.font.main
      font.pointSize: Style.font.tiny
      Layout.preferredWidth: 32 * Config.scale
      Layout.alignment: Qt.AlignVCenter
    }
  }

  // One selectable device; the default carries a check mark.
  component DeviceRow: Rectangle {
    id: dev
    required property var modelData
    required property bool isDefault
    signal picked()

    Layout.fillWidth: true
    implicitHeight: Style.audio.rowHeight
    color: area.containsMouse ? Style.colors.gray1 : "transparent"
    Behavior on color {
      ColorAnimation { duration: Style.durations.hover; easing.type: Easing.OutQuad }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (!dev.isDefault) dev.picked()
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.spacing.p1
      anchors.rightMargin: Style.spacing.p1
      spacing: Style.spacing.p1

      Text {
        text: root.checkGlyph
        opacity: dev.isDefault ? 1 : 0
        color: Style.colors.accent
        font.family: Style.font.symbols
        font.pointSize: Style.font.small
        Layout.preferredWidth: Style.font.size3
      }
      Text {
        text: AudioData.nodeLabel(dev.modelData)
        elide: Text.ElideRight
        color: dev.isDefault ? Style.colors.brightWhite : Style.colors.white
        font.family: Style.font.main
        font.pointSize: Style.font.small
        Layout.fillWidth: true
      }
    }
  }

  // ── Panel ──────────────────────────────────────────────────────────────

  BorderRect {
    id: panel

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: root.panelHeight

    // 0 == fully open, -panelHeight == fully hidden behind the bar.
    y: root.active ? 0 : -root.panelHeight

    color: Style.colors.black
    borderColor: Style.colors.gray2
    borderWidth: Style.bar.borderWidth

    Behavior on y {
      NumberAnimation {
        duration: Style.durations.small
        easing.type: Easing.InOutCubic
      }
    }

    // Swallow clicks so they don't reach shell.qml's close-on-click-outside.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Flickable {
      anchors.fill: parent
      anchors.margins: Style.spacing.p2
      contentHeight: content.implicitHeight
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      ColumnLayout {
        id: content
        width: parent.width
        spacing: 0

        // ── Output ───────────────────────────────────────────────────
        SectionTitle { glyph: AudioData.sinkIcon(AudioData.sink); text: "Output" }
        VolumeRow {
          visible: !!AudioData.sink
          node: AudioData.sink
          glyph: AudioData.sinkIcon(AudioData.sink)
          mutedGlyph: root.speakerMutedGlyph
        }
        Repeater {
          model: AudioData.sinks
          DeviceRow {
            isDefault: modelData === AudioData.sink
            onPicked: AudioData.setDefaultSink(modelData)
          }
        }
        Hint {
          id: noOutputs
          visible: AudioData.sinks.length === 0
          text: "No output devices"
        }

        // ── Input ────────────────────────────────────────────────────
        SectionTitle { glyph: root.micGlyph; text: "Input" }
        VolumeRow {
          visible: !!AudioData.source
          node: AudioData.source
          glyph: root.micGlyph
          mutedGlyph: root.micMutedGlyph
        }
        Repeater {
          model: AudioData.sources
          DeviceRow {
            isDefault: modelData === AudioData.source
            onPicked: AudioData.setDefaultSource(modelData)
          }
        }
        Hint {
          id: noInputs
          visible: AudioData.sources.length === 0
          text: "No input devices"
        }

        // ── Applications ─────────────────────────────────────────────
        SectionTitle { glyph: root.appsGlyph; text: "Applications" }
        Repeater {
          model: AudioData.appStreams
          VolumeRow {
            required property var modelData
            node: modelData
            label: AudioData.nodeLabel(modelData)
            glyph: AudioData.sinkIcon(null)
            mutedGlyph: root.speakerMutedGlyph
          }
        }
        Hint {
          id: nothingPlaying
          visible: AudioData.appStreams.length === 0
          text: "Nothing playing"
        }
      }
    }
  }
}
