// Transient volume/brightness readout. Noctalia had one; roosta does not -- his
// bar's AudioButton auto-expands instead. Shown only on the focused monitor so a
// volume tap doesn't flash on all three screens at once.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.config

Item {
  id: root
  required property string monitorId

  property string kind: "volume"     // volume | brightness
  property real level: 0
  property bool muted: false
  property bool shown: false

  readonly property bool onFocused: Hyprland.focusedMonitor?.name === root.monitorId

  visible: shown && onFocused
  implicitWidth: 260
  implicitHeight: 64

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.top: parent.top
  anchors.topMargin: Style.bar.height + Style.spacing.p5

  function flash(k, lvl, isMuted) {
    root.kind = k;
    root.level = lvl;
    root.muted = isMuted ?? false;
    root.shown = true;
    hideTimer.restart();
  }

  Timer { id: hideTimer; interval: 1800; onTriggered: root.shown = false }

  // Ignore the initial binding pass, or the OSD flashes at startup.
  property bool ready: false
  Timer { interval: 1500; running: true; onTriggered: root.ready = true }

  Connections {
    target: AudioData
    function onVolumeChanged() {
      if (root.ready && AudioData.ready) root.flash("volume", AudioData.volume, AudioData.sink?.audio?.muted ?? false);
    }
  }

  Connections {
    target: Brightness
    function onChanged() {
      if (root.ready && Brightness.available) root.flash("brightness", Brightness.value, false);
    }
  }

  BorderRect {
    anchors.fill: parent
    color: Style.colors.black
    borderColor: Style.colors.gray3
    borderWidth: Style.bar.borderWidth

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.spacing.p3
      spacing: Style.spacing.p3

      Text {
        text: {
          if (root.kind === "brightness") return "󰃠";
          if (root.muted) return "󰝟";
          if (root.level <= 0.01) return "󰕿";
          if (root.level < 0.5) return "󰖀";
          return "󰕾";
        }
        font.family: Style.font.symbols
        font.pointSize: Style.font.xl
        color: root.muted ? Style.colors.brightBlack : Style.colors.brightWhite
        Layout.alignment: Qt.AlignVCenter
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 6
        color: Style.colors.gray3

        Rectangle {
          height: parent.height
          width: parent.width * Math.max(0, Math.min(1, root.level))
          color: root.muted ? Style.colors.brightBlack : Style.colors.accent
          Behavior on width { NumberAnimation { duration: Style.durations.tiny } }
        }
      }

      Text {
        text: root.muted && root.kind === "volume" ? "muted" : `${Math.round(root.level * 100)}%`
        font.family: Style.font.main
        font.pointSize: Style.font.small
        color: Style.colors.white
        Layout.alignment: Qt.AlignVCenter
        Layout.minimumWidth: 42
        horizontalAlignment: Text.AlignRight
      }
    }
  }

  opacity: shown ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: Style.durations.small } }
}
