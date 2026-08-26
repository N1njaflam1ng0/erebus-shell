// Host-specific values: monitor names, audio sinks, and the helper binaries the
// shell shells out to.
//
// This checked-in copy uses bare binary names so `qs -p assets/quickshell` works
// straight from a dev shell. The Nix module overwrites it with a generated copy
// that pins absolute store paths and the real per-host monitor layout — see
// modules/features/desktop/quickshell/quickshell.nix.

pragma Singleton
import Quickshell

Singleton {
  id: root

  // Outputs, by role. Empty string = this host has no monitor in that role.
  readonly property string primary: "DP-1"
  readonly property string left: "DP-3"
  readonly property string right: "HDMI-A-1"

  // Every output the bar should draw on. Anything not listed still gets a bar,
  // using the primary layout.
  readonly property var outputs: ["DP-1", "DP-3", "HDMI-A-1"]

  readonly property string terminal: "ghostty"

  // Helper binaries. Nix replaces each with an absolute store path.
  readonly property string power: "erebus-power"
  readonly property string screenshot: "erebus-screenshot"
  readonly property string colorpicker: "erebus-colorpicker"
  readonly property string audioSwitch: "erebus-audio-switch"
  readonly property string monitors: "erebus-monitors"
  readonly property string clipboard: "erebus-clipboard"
  readonly property string wallpaper: "erebus-wallpaper"
  readonly property string calendar: "erebus-calendar"
  readonly property string brightnessctl: "brightnessctl"
  readonly property string sysmon: "btop"
  readonly property string cava: "cava"
  readonly property string hyprctl: "hyprctl"

  // PipeWire sink node names, for picking the bar's output icon.
  readonly property string sinkHeadphones: "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headphones__sink"
  readonly property string sinkHeadset: "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headset__sink"
  readonly property string sinkHdmi: "alsa_output.pci-0000_01_00.1.hdmi-stereo"
  readonly property string sinkSpdif: "alsa_output.pci-0000_00_1f.3.iec958-stereo"
}
