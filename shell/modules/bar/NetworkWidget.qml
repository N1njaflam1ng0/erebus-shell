// Network, via Quickshell.Networking. Shows wifi signal strength when the active
// device is wireless, a plug when wired, and dims when there is no connectivity.
//
// NOTE: Networking.devices is a lazily-populated ObjectModel — reading `.values`
// from a plain binding does NOT fill it (verified: stays empty indefinitely). It
// only populates once something consumes the model, hence the tracker Repeater
// below. Same for Bluetooth.devices and Mpris.players.

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell.Networking
import qs.config

Rectangle {
  id: root

  // Bumped by the tracker so the bindings below re-evaluate on population.
  property int deviceGeneration: 0

  readonly property var devs: {
    root.deviceGeneration;   // dependency, forces re-evaluation
    return Networking.devices?.values ?? [];
  }
  readonly property var active: devs.find(d => d.connected) ?? null
  readonly property bool isWifi: (active?.type ?? DeviceType.None) === DeviceType.Wifi
  readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
  readonly property var activeNetwork: isWifi
    ? ((active?.networks?.values ?? []).find(n => n.connected) ?? null)
    : null
  readonly property int signal: activeNetwork?.signalStrength ?? 0

  implicitWidth: childrenRect.width
  implicitHeight: parent.height
  color: "transparent"

  readonly property var wifiRamp: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

  // Non-visual: exists purely to make the model populate and to notice changes.
  // Must be Instantiator, not Repeater -- Repeater requires Item delegates.
  Instantiator {
    model: Networking.devices
    delegate: QtObject {
      required property var modelData
      readonly property bool conn: modelData?.connected ?? false
      onConnChanged: root.deviceGeneration++
      Component.onCompleted: root.deviceGeneration++
      Component.onDestruction: root.deviceGeneration++
    }
  }

  RowLayout {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.p0

    Text {
      text: {
        if (root.active === null) return "󰤭";              // disconnected
        if (!root.isWifi) return "󰈁";                       // wired
        return root.wifiRamp[Math.min(4, Math.floor(root.signal / 25))];
      }
      font.family: Style.font.symbols
      font.pointSize: Style.font.small
      color: {
        if (root.active === null) return Style.colors.brightBlack;
        if (!root.online) return Style.colors.brightYellow;   // portal / limited
        return Style.colors.white;
      }
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
