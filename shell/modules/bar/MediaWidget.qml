// MPRIS media widget. roosta imports Quickshell.Services.Mpris in AudioData.qml
// but never renders it; your noctalia bar had a media widget with a scrolling
// title, so this fills that gap.

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell.Services.Mpris
import qs.config

Rectangle {
  id: root

  // Prefer whatever is actually playing; otherwise fall back to the first player
  // so a paused track still shows.
  // Mpris.players is lazily populated like Networking.devices; the tracker below
  // forces it and re-triggers this binding. See NetworkWidget.qml.
  property int playerGeneration: 0
  readonly property var players: {
    root.playerGeneration;
    return Mpris.players?.values ?? [];
  }
  readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
  readonly property bool active: player !== null

  visible: active
  implicitWidth: active ? layout.implicitWidth : 0
  implicitHeight: parent.height
  color: "transparent"

  function label() {
    if (!active) return "";
    const title = player.trackTitle || "Unknown";
    const artist = player.trackArtist || "";
    return artist ? `${artist} — ${title}` : title;
  }

  Instantiator {
    model: Mpris.players
    delegate: QtObject {
      required property var modelData
      readonly property bool playing: modelData?.isPlaying ?? false
      onPlayingChanged: root.playerGeneration++
      Component.onCompleted: root.playerGeneration++
      Component.onDestruction: root.playerGeneration++
    }
  }

  RowLayout {
    id: layout
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.p1

    Text {
      text: root.player?.isPlaying ? "" : ""
      font.family: Style.font.symbols
      font.pointSize: Style.font.small
      color: Style.colors.brightGreen
      Layout.alignment: Qt.AlignVCenter

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.player?.canTogglePlaying) root.player.togglePlaying()
      }
    }

    // Clipped rather than elided so a long title can scroll on hover.
    Item {
      Layout.alignment: Qt.AlignVCenter
      implicitHeight: title.implicitHeight
      implicitWidth: Math.min(title.implicitWidth, 220)
      clip: true

      Text {
        id: title
        text: root.label()
        font.family: Style.font.main
        font.pointSize: Style.font.small
        color: Style.colors.white

        // Only animate when the text actually overflows.
        readonly property real overflow: Math.max(0, title.implicitWidth - 220)
        SequentialAnimation on x {
          running: hover.hovered && title.overflow > 0
          loops: Animation.Infinite
          NumberAnimation { from: 0; to: -title.overflow; duration: 40 * title.overflow; easing.type: Easing.Linear }
          PauseAnimation { duration: 800 }
          NumberAnimation { from: -title.overflow; to: 0; duration: 300; easing.type: Easing.OutQuad }
          PauseAnimation { duration: 800 }
        }
        onTextChanged: x = 0
      }

      HoverHandler { id: hover }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
    onClicked: mouse => {
      if (!root.player) return;
      if (mouse.button === Qt.MiddleButton && root.player.canTogglePlaying) root.player.togglePlaying();
      else if (mouse.button === Qt.ForwardButton && root.player.canGoNext) root.player.next();
      else if (mouse.button === Qt.BackButton && root.player.canGoPrevious) root.player.previous();
    }
    // Scroll to skip tracks.
    onWheel: wheel => {
      if (!root.player) return;
      if (wheel.angleDelta.y > 0 && root.player.canGoNext) root.player.next();
      else if (wheel.angleDelta.y < 0 && root.player.canGoPrevious) root.player.previous();
    }
  }
}
