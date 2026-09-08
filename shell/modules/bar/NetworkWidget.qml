// Network, via Quickshell.Networking. Shows wifi signal strength when the active
// device is wireless, a plug when wired, and dims when there is no connectivity.
// The label next to it is the SSID on wifi and the interface on ethernet.
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

  // Bumped by the trackers so the bindings below re-evaluate on population.
  property int deviceGeneration: 0
  property int networkGeneration: 0

  readonly property var devs: {
    root.deviceGeneration;   // dependency, forces re-evaluation
    return Networking.devices?.values ?? [];
  }
  readonly property var active: devs.find(d => d.connected) ?? null
  readonly property bool isWifi: (active?.type ?? DeviceType.None) === DeviceType.Wifi
  readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
  readonly property var activeNetwork: {
    root.networkGeneration;  // same, for the per-device network list
    return root.isWifi
      ? ((root.active?.networks?.values ?? []).find(n => n.connected) ?? null)
      : null;
  }
  // 0.0 - 1.0, like UPower's battery percentage.
  readonly property real signal: activeNetwork?.signalStrength ?? 0
  // SSID on wifi; on ethernet the device name is the interface, e.g. enp2s0.
  readonly property string label: root.isWifi ? (activeNetwork?.name ?? "") : (active?.name ?? "")

  implicitWidth: childrenRect.width
  implicitHeight: parent.height
  color: "transparent"

  readonly property var wifiRamp: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

  // Non-visual: exists purely to make the model populate and to notice changes.
  // Must be Instantiator, not Repeater -- Repeater requires Item delegates.
  Instantiator {
    model: Networking.devices
    delegate: QtObject {
      id: devTracker
      required property var modelData
      readonly property bool conn: modelData?.connected ?? false
      onConnChanged: root.deviceGeneration++
      Component.onCompleted: root.deviceGeneration++
      Component.onDestruction: root.deviceGeneration++

      // Each device's network list is lazily populated the same way, and nothing
      // consumed it before: without this the connected AP is never found, so the
      // SSID stays empty and signalStrength reads 0 no matter the real strength.
      property var networkTracker: Instantiator {
        model: devTracker.modelData?.networks ?? null
        delegate: QtObject {
          required property var modelData
          readonly property bool conn: modelData?.connected ?? false
          onConnChanged: root.networkGeneration++
          Component.onCompleted: root.networkGeneration++
          Component.onDestruction: root.networkGeneration++
        }
      }
    }
  }

  RowLayout {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.p0

    Text {
      text: {
        if (root.active === null) return "󰤭";              // disconnected
        if (!root.isWifi) return "󰈁";                       // wired
        return root.wifiRamp[Math.min(4, Math.floor(root.signal * 5))];
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

    Text {
      // Nothing connected: the dimmed icon says it on its own, so stay silent
      // rather than reserving width for a placeholder.
      visible: root.label !== ""
      text: root.label
      font.family: Style.font.main
      font.pointSize: Style.font.small
      color: Style.colors.white
      // A long SSID must not push the clock around; 140px fits most of them.
      elide: Text.ElideRight
      Layout.maximumWidth: 140
      Layout.alignment: Qt.AlignVCenter
      Layout.leftMargin: Style.spacing.p1
    }
  }
}
