// ┌───────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░░█▀█░█░█░█▀▄░▀█▀░█▀█░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░░█▀█░█░█░█░█░░█░░█░█░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░░▀░▀░▀▀▀░▀▀░░▀▀▀░▀▀▀░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀───────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>      ├┤
// ││ Repo    : https://github.com/roosta/dotfiles││
// ││ Site    : https://www.roosta.sh             ││
// ├┤ License : GNU General Public License v3     ├┤
// ┆└─────────────────────────────────────────────┘┆

pragma ComponentBehavior: Bound
import qs.config
import qs.services
import qs.components
import qs
import QtQuick
import QtQuick.Layouts

import QtQuick.Controls

ExpandingButton {
  id: root

  property bool muted: AudioData.ready && AudioData.sink.audio.muted
  property string mutedIcon: ""

  // sinkIcon never returns "": an empty label collapses both this button and
  // srcBtn to zero width, which is how the output picker once ended up
  // unclickable.
  buttonLabel: muted ? mutedIcon : AudioData.sinkIcon(AudioData.sink)
  open: GlobalState.audioOpen && GlobalState.audioMonitorId === root.monitorId

  // Expands when scrolled, not on every volume change: volume keys already get
  // the Osd, and expanding here re-laid out the bar on every monitor per tap.
  function peek() {
    root.active = true
    timer.restart()
  }

  Timer {
    id: timer
    running: false
    interval: 1000 * 10
    onTriggered: {
      root.active = false
    }
  }

  property var openAudioMenu: () => {
    const i = Config.outputs.findIndex(o => o.sink === AudioData.sink.name)
    GlobalState.openLauncher({
      id: root.monitorId,
      mode: "audio",
      direction: Qt.RightToLeft,
      index: i > -1 ? i : 0
    })
  }

  onRightClick: openAudioMenu

  // Opens the audio panel. While scrolling has the inline slider out the
  // button shows a chevron instead, and a click folds the slider back first.
  onLeftClick: () => {
    if (root.active) {
      root.active = false
    } else {
      GlobalState.toggleAudio(root.monitorId)
    }
  }

  wheelHandler: (event) => {
    root.peek()
    if (event.angleDelta.y > 0) {
      AudioData.incrementVolume()
    } else if (event.angleDelta.y < 0) {
      AudioData.decrementVolume()
    }
  }

  BorderRect {
    id: srcBtn
    visible: root.active
    implicitWidth: srcBtnText.implicitWidth + Style.spacing.p2 * 2
    implicitHeight: srcBtnText.implicitHeight
    color: Style.colors.black
    states: [
      State {
        name: "hovered"
        when: srcMouse.containsMouse
        PropertyChanges { srcBtnText.color: Style.colors.brightWhite }
        PropertyChanges { srcMouse.cursorShape: Qt.PointingHandCursor }
      }
    ]
    MouseArea {
      id: srcMouse
      hoverEnabled: true
      anchors.fill: parent
      onClicked: root.openAudioMenu()
    }

    transitions: [
      Transition {
        ColorAnimation {
          duration: Style.durations.small
          easing.type: Easing.OutQuad
        }
      }
    ]
    Text {
      anchors.centerIn: parent
      color: Style.colors.white
      id: srcBtnText
      text: root.buttonLabel
      font {
        family: Style.font.light
        pixelSize: Style.font.size3
      }
    }
  }
  BorderRect {
    id: inputBtn
    visible: root.active
    implicitWidth: inputBtnText.implicitWidth + Style.spacing.p2 * 2
    implicitHeight: inputBtnText.implicitHeight
    color: Style.colors.black
    states: [
      State {
        name: "hovered"
        when: inputMouse.containsMouse
        PropertyChanges { inputBtnText.color: Style.colors.brightWhite }
        PropertyChanges { inputMouse.cursorShape: Qt.PointingHandCursor }
      }
    ]
    MouseArea {
      id: inputMouse
      hoverEnabled: true
      anchors.fill: parent
      onClicked: AudioData.toggleSourceMute()
    }

    transitions: [
      Transition {
        ColorAnimation {
          duration: Style.durations.small
          easing.type: Easing.OutQuad
        }
      }
    ]
    Text {
      anchors.centerIn: parent
      color: Style.colors.white
      id: inputBtnText
      text: {
        if (AudioData.source?.audio?.muted) {
          return "󰍭"
        } else {
          return ""
        }
      }
      font {
        family: Style.font.light
        pixelSize: Style.font.size3
      }
    }
  }

  VolumeSlider {
    visible: root.active
    implicitWidth: Style.bar.sliderWidth
    node: AudioData.sink
  }
}
