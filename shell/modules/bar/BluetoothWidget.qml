// Bluetooth, via Quickshell.Bluetooth. Hidden when the host has no adapter.

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell.Bluetooth
import qs.config

Rectangle {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool hasAdapter: adapter !== null
  readonly property bool enabled: adapter?.enabled ?? false
  // Bluetooth.devices is lazily populated like Networking.devices; the tracker
  // below forces it and re-triggers this binding. See NetworkWidget.qml.
  property int deviceGeneration: 0
  readonly property var connectedDevices: {
    root.deviceGeneration;
    return (Bluetooth.devices?.values ?? []).filter(d => d.connected);
  }

  visible: hasAdapter
  implicitWidth: hasAdapter ? childrenRect.width : 0
  implicitHeight: parent.height
  color: "transparent"

  Instantiator {
    model: Bluetooth.devices
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
      text: root.enabled ? (root.connectedDevices.length > 0 ? "" : "") : ""
      font.family: Style.font.symbols
      font.pointSize: Style.font.small
      color: {
        if (!root.enabled) return Style.colors.brightBlack;
        return root.connectedDevices.length > 0 ? Style.colors.brightBlue : Style.colors.white;
      }
      Layout.alignment: Qt.AlignVCenter
    }
    Text {
      visible: root.connectedDevices.length > 1
      text: root.connectedDevices.length
      font.family: Style.font.main
      font.pointSize: Style.font.tiny
      color: Style.colors.white
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
