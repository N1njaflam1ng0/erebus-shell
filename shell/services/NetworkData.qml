// Shared NetworkManager state for the bar widget (modules/bar/NetworkWidget.qml)
// and the dropdown (modules/network/WifiPanel.qml), via Quickshell.Networking.
//
// NOTE: Networking.devices and device.networks are lazily-populated ObjectModels
// — reading `.values` from a plain binding does NOT fill them (verified: stays
// empty indefinitely). They only populate once something consumes the model,
// hence the tracker Instantiators below, which also bump the generation counters
// so the derived bindings re-evaluate when the models change under them. This
// lives here rather than in each consumer so there is one copy of that
// workaround, not two drifting apart. Same story for Bluetooth.devices and
// Mpris.players.

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Networking

Singleton {
  id: root

  // Bumped by the trackers so the bindings below re-evaluate on population.
  property int deviceGeneration: 0
  property int networkGeneration: 0

  readonly property var devices: {
    root.deviceGeneration;   // dependency, forces re-evaluation
    return Networking.devices?.values ?? [];
  }

  readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var activeDevice: root.devices.find(d => d.connected) ?? null
  readonly property bool isWifi: (root.activeDevice?.type ?? DeviceType.None) === DeviceType.Wifi

  readonly property var activeNetwork: {
    root.networkGeneration;  // same, for the per-device network list
    return root.isWifi
      ? ((root.activeDevice?.networks?.values ?? []).find(n => n.connected) ?? null)
      : null;
  }

  // 0.0 - 1.0, like UPower's battery percentage.
  readonly property real signal: activeNetwork?.signalStrength ?? 0
  // SSID on wifi; on ethernet the device name is the interface, e.g. enp2s0.
  readonly property string label: root.isWifi ? (activeNetwork?.name ?? "") : (activeDevice?.name ?? "")

  // Every visible wifi network, deduped and ordered for the panel: connected
  // first, then saved, then by strength. Hidden APs come through with a blank
  // name and are dropped — there is nothing to click on and no way to join one
  // from a list.
  //
  // Deliberately recomputed only on networkGeneration (membership changes), not
  // on every signalStrength tick: each row binds straight to its own network
  // object, so strengths stay live while the rows hold still under the cursor.
  readonly property var sortedNetworks: {
    root.networkGeneration;
    const all = root.wifiDevice?.networks?.values ?? [];
    const seen = ({});
    const out = [];
    for (const n of all) {
      if (!n || !n.name)
        continue;
      const at = seen[n.name];
      if (at === undefined) {
        seen[n.name] = out.length;
        out.push(n);
      } else if (!out[at].connected && (n.connected || n.signalStrength > out[at].signalStrength)) {
        // Same SSID on another band or another AP: keep whichever one is
        // connected, else the stronger of the two.
        out[at] = n;
      }
    }
    out.sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1;
      if (a.known !== b.known) return a.known ? -1 : 1;
      return b.signalStrength - a.signalStrength;
    });
    return out;
  }

  // What the panel actually lists. Held still while `frozen`, because a
  // ListView whose model is a JS array rebuilds *every* delegate when that
  // array is replaced (verified) -- and a scan result landing mid-typing would
  // otherwise destroy the password field, taking the half-typed password and
  // the keyboard focus with it.
  property var networks: []
  property bool frozen: false

  onSortedNetworksChanged: root.publish()
  onFrozenChanged: root.publish()

  function publish(): void {
    if (!root.frozen)
      root.networks = root.sortedNetworks;
  }

  // 802.1X networks (eduroam, DTUsecure and friends) need an identity, an EAP
  // method and usually a CA certificate. None of that fits in a one-line
  // password box, and connectWithPsk() is not the call for them -- the panel
  // hands an unsaved enterprise network to nm-connection-editor instead.
  // Already-saved ones connect() normally, since NM holds the profile.
  function isEnterprise(net: var): bool {
    switch (net?.security) {
    case WifiSecurityType.WpaEap:
    case WifiSecurityType.Wpa2Eap:
    case WifiSecurityType.Wpa3SuiteB192:
    case WifiSecurityType.DynamicWep:
    case WifiSecurityType.Leap:
      return true;
    default:
      return false;
    }
  }

  // Driven by the panel: scanning is only worth its airtime and power while
  // someone is looking at the list.
  property bool scanning: false

  onScanningChanged: root.applyScanner()
  onWifiDeviceChanged: root.applyScanner()

  function applyScanner(): void {
    const d = root.wifiDevice;
    if (d)
      d.scannerEnabled = root.scanning;
  }

  // NetworkManager decides on its own when to re-sweep while a scan client is
  // active, so a manual rescan is a matter of dropping and re-taking the
  // scanner rather than calling anything.
  function rescan(): void {
    const d = root.wifiDevice;
    if (!d || !root.scanning)
      return;
    d.scannerEnabled = false;
    rescanTimer.restart();
  }

  Timer {
    id: rescanTimer
    interval: 120
    onTriggered: root.applyScanner()
  }

  // Non-visual: exists purely to make the models populate and to notice changes.
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
          // `known` flips on connect-with-password and on forget, and both
          // change where the row sorts.
          readonly property bool saved: modelData?.known ?? false
          onConnChanged: root.networkGeneration++
          onSavedChanged: root.networkGeneration++
          Component.onCompleted: root.networkGeneration++
          Component.onDestruction: root.networkGeneration++
        }
      }
    }
  }
}
