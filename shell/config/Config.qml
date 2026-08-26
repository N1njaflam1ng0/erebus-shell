// Adapted from roosta/dotfiles (.config/quickshell/config/Config.qml, GPLv3).
// Host-specific values moved out to Host.qml; roosta's ~/scripts entries replaced
// with the helper binaries built in modules/features/desktop/quickshell/.

pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import qs.utils
import qs.config
import QtQuick

Singleton {
  id: root

  // wip: planned scale per display
  property real scale: 1.0

  // Default apps
  readonly property string terminal: Host.terminal
  readonly property string shell: "fish"
  readonly property string menuPrefix: "/"

  // Available displays, by role. Roles this host doesn't have are "".
  component Displays: QtObject {
    readonly property string left: Host.left
    readonly property string right: Host.right
    readonly property string center: Host.primary
  }
  readonly property Displays displays: Displays { }

  // Primary display
  readonly property string primaryDisplay: Host.primary

  // default menu mode
  readonly property string defaultMode: "apps"

  component Notifications: QtObject {
    readonly property int timeout: 7000
  }

  readonly property Notifications notifications: Notifications { }

  property var keyboardLayouts: [
    {
      code: "dk",
      label: "Danish",
      color: Style.colors.accent,
      default: true
    },
    {
      code: "en",
      label: "English (US)",
      color: Style.colors.fg,
      default: false
    }
  ]

  // Menu modes, defaults to apps
  readonly property var launcherMenus: [
    {
      id: "erebus-mode-apps",
      name: "Applications",
      comment: "Browse and launch desktop applications",
      mode: "apps",
      genericName: "Menu",
      categories: ["AppLauncher"],
      iconId: "applications-all"
    },
    {
      id: "erebus-mode-utils",
      name: "Utilities",
      comment: "Screenshots, colour picking and system monitoring",
      mode: "utils",
      genericName: "Menu",
      categories: ["Utility", "FileTools"],
      iconId: "applications-utilities"
    },
    {
      id: "erebus-mode-audio",
      name: "Audio",
      comment: "Switch the default audio output",
      mode: "audio",
      genericName: "Menu",
      categories: ["Audio", "Configuration"],
      iconId: "audio-x-generic"
    },
    {
      id: "erebus-mode-display",
      name: "Display",
      comment: "Arrange monitors and toggle mirroring",
      mode: "display",
      genericName: "Menu",
      categories: ["Display", "Configuration"],
      iconId: "preferences-desktop-display"
    },
    {
      id: "erebus-mode-clipboard",
      name: "Clipboard",
      comment: "Pick an entry from clipboard history",
      mode: "clipboard",
      genericName: "Menu",
      categories: ["Clipboard", "System"],
      iconId: "edit-paste"
    },
    {
      id: "erebus-mode-wallpaper",
      name: "Wallpaper",
      comment: "Set the wallpaper on every monitor, still or animated",
      mode: "wallpaper",
      genericName: "Menu",
      categories: ["Wallpaper", "Configuration"],
      iconId: "preferences-desktop-wallpaper"
    },
    {
      id: "erebus-mode-power",
      name: "Power",
      comment: "Power options for system (shutdown, restart, logout etc)",
      mode: "power",
      genericName: "Menu",
      categories: ["System", "Power"],
      iconId: "preferences-system"
    },
    {
      id: "erebus-mode-notifications",
      name: "Notifications",
      comment: "Notification control menu",
      mode: "notifications",
      genericName: "Menu",
      categories: ["System"],
      iconId: "notifications"
    }
  ]

  readonly property var powerScripts: [
    {
      id: "erebus-power-shutdown",
      name: "Shutdown",
      comment: "Power down system",
      genericName: "Power",
      categories: ["System", "Shutdown"],
      script: [Host.power, "shutdown"],
      iconId: "system-shutdown"
    },
    {
      id: "erebus-power-reboot",
      name: "Reboot",
      comment: "Restart system",
      genericName: "Power",
      categories: ["System", "Restart"],
      script: [Host.power, "reboot"],
      iconId: "system-reboot"
    },
    {
      id: "erebus-power-logout",
      name: "Log out",
      comment: "Log out current user",
      genericName: "Power",
      categories: ["System", "LogOut"],
      script: [Host.power, "logout"],
      iconId: "system-log-out"
    },
    {
      id: "erebus-power-lock",
      name: "Lock",
      comment: "Lock current session",
      genericName: "Power",
      categories: ["System", "Lock"],
      script: [Host.power, "lock"],
      iconId: "system-lock-screen"
    },
    {
      id: "erebus-power-suspend",
      name: "Suspend",
      comment: "Suspend to RAM",
      genericName: "Power",
      categories: ["System", "Suspend"],
      script: [Host.power, "suspend"],
      iconId: "system-suspend"
    },
    {
      id: "erebus-power-hibernate",
      name: "Hibernate",
      comment: "Suspend to disk",
      genericName: "Power",
      categories: ["System", "Hibernate"],
      script: [Host.power, "hibernate"],
      iconId: "system-hibernate"
    }
  ]

  readonly property var utilities: [
    {
      id: "erebus-utils-screenshot",
      name: "Screenshot",
      comment: "Select a region, then annotate it",
      genericName: "Utility",
      categories: ["Utility", "ImageProcessing"],
      script: [Host.screenshot, "region"],
      iconId: "accessories-screenshot"
    },
    {
      id: "erebus-utils-screenshot-output",
      name: "Screenshot (monitor)",
      comment: "Capture the focused monitor, then annotate it",
      genericName: "Utility",
      categories: ["Utility", "ImageProcessing"],
      script: [Host.screenshot, "output"],
      iconId: "accessories-screenshot"
    },
    {
      id: "erebus-utils-colorpicker",
      name: "Colour picker",
      comment: "Pick a hex colour from the screen into the clipboard",
      genericName: "Utility",
      categories: ["Utility", "ImageProcessing"],
      script: [Host.colorpicker],
      iconId: "color-picker"
    },
    {
      id: "erebus-utils-monitor",
      name: "System Monitor",
      comment: "Monitor system resource usage",
      genericName: "Utility",
      categories: ["Utility", "Monitor"],
      script: [Config.terminal, "-e", Host.sysmon],
      iconId: "utilities-system-monitor"
    }
  ]

  // Display actions. The full monitor panel lands in phase 2; these drive the
  // same helper it will use.
  readonly property var displayLayouts: [
    {
      id: "erebus-display-arrange",
      name: "Arrange displays",
      comment: "Open the graphical display arranger (wdisplays)",
      genericName: "Display",
      categories: ["Display", "Configuration"],
      script: [Host.monitors, "arrange"],
      iconId: "preferences-desktop-display"
    },
    {
      id: "erebus-display-mirror",
      name: "Mirror displays",
      comment: "Mirror one monitor onto another, or undo an active mirror",
      genericName: "Display",
      categories: ["Display", "Mirror"],
      script: [Host.monitors, "mirror"],
      iconId: "preferences-desktop-remote-desktop"
    },
    {
      id: "erebus-display-save",
      name: "Save monitor layout",
      comment: "Write the current arrangement to ~/.config/hypr/monitors.lua",
      genericName: "Display",
      categories: ["Display", "Configuration"],
      script: [Host.monitors, "save"],
      iconId: "document-save"
    }
  ]

  // Audio output sinks. `sink` is matched against the PipeWire node name to pick
  // the bar icon; `script` switches the default sink.
  readonly property var outputs: [
    {
      id: 0,
      sink: Host.sinkHeadphones,
      icon: "󰋋",
      comment: "Switch audio output to the INZONE headset (Game)",
      genericName: "Audio",
      categories: ["Audio", "Headphones"],
      iconId: "audio-headphones",
      name: "Headphones (Game)",
      script: [Host.audioSwitch, "headphones"]
    },
    {
      id: 1,
      sink: Host.sinkHeadset,
      icon: "󰋎",
      comment: "Switch audio output to the INZONE headset (Chat)",
      genericName: "Audio",
      categories: ["Audio", "Headset"],
      iconId: "audio-headset",
      name: "Headset (Chat)",
      script: [Host.audioSwitch, "headset"]
    },
    {
      id: 2,
      sink: Host.sinkHdmi,
      icon: "󰍹",
      comment: "Switch audio output to HDMI",
      genericName: "Audio",
      categories: ["Audio", "TV"],
      iconId: "video-display",
      name: "HDMI",
      script: [Host.audioSwitch, "hdmi"]
    },
    {
      id: 3,
      sink: Host.sinkSpdif,
      icon: "󰓃",
      comment: "Switch audio output to the built-in S/PDIF",
      genericName: "Audio",
      categories: ["Audio", "Speakers"],
      iconId: "audio-speakers",
      name: "Built-in (S/PDIF)",
      script: [Host.audioSwitch, "spdif"]
    }
  ]

  readonly property var audioOptions: [
    {
      id: 0,
      genericName: "Audio",
      categories: ["Audio", "Mute", "Output"],
      comment: "Toggle mute on default output sink",
      iconId: "audio-volume-muted",
      name: "Toggle output mute",
      script: [Host.audioSwitch, "mute-output"]
    },
    {
      id: 1,
      genericName: "Audio",
      categories: ["Audio", "Mute", "Input"],
      comment: "Toggle mute on default input microphone",
      iconId: "microphone-sensitivity-muted",
      name: "Toggle input mute",
      script: [Host.audioSwitch, "mute-input"]
    }
  ]

  // icon aliases, if a class/appid matches key, use value
  // in cases where there isn't a good icon match
  readonly property var aliases: [
    [/.*spotify.*/i, "spotify"],
    [/^steam_app_(\d+)$/, "steam_icon_$1"],
    [/.*ghostty.*/i, "terminal"],
    [/kitty/i, "terminal"],
    [/.*pavucontrol.*/, "gnome-volume-control"],
    [/org.satty.satty/i, "image"],
    [/.*code.*/i, "vscode"],
    [/firefox-devedition/i, "firefox-developer-edition"]
  ]

  // Move to something interactive via the menu, but this'll do for now
  property var favorites: [
    "firefox-devedition",
    "com.mitchellh.ghostty",
    "code",
    "discord",
    "spotify",
    "steam",
    "org.gnome.Nautilus",
    "obsidian",
    "org.prismlauncher.PrismLauncher"
  ]
}
