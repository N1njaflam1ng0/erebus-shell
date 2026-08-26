// ┌───────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░░█▀▀░▀█▀░█░█░█░░░█▀▀░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░░▀▀█░░█░░░█░░█░░░█▀▀░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░░▀▀▀░░▀░░░▀░░▀▀▀░▀▀▀░░░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀───────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>      ├┤
// ││ Repo    : https://github.com/roosta/dotfiles││
// ││ Site    : https://www.roosta.sh             ││
// ├┤ License : GNU General Public License v3     ├┤
// ┆└─────────────────────────────────────────────┘┆

pragma Singleton
// pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.config

Singleton {
  id: root

  // Palette lives in Colors.qml so matugen can regenerate it without touching
  // any widget. Widgets read these as `Style.colors.<slot>`.
  readonly property var colors: Colors


  component Notifications: QtObject {
    readonly property int timeout: 7000
    readonly property int toastWidth: 350
    readonly property int toastHeight: 100
  }

  readonly property Notifications notifications: Notifications { }

  component Bar: QtObject {
    readonly property int height: 40 * Config.scale
    readonly property bool transparent: false
    readonly property int radius: 0 * Config.scale
    readonly property real borderWidth: 1 * Config.scale
    readonly property int sliderWidth: 120 * Config.scale
    readonly property real iconSize: 20 * Config.scale
  }
  readonly property Bar bar: Bar {}

  component Launcher: QtObject {
    readonly property int height: 300
  }
  readonly property Launcher launcher: Launcher { }

  component Calendar: QtObject {
    readonly property int width: 380 * Config.scale
    readonly property int height: 420 * Config.scale
    // One cell of the 7x6 month grid.
    readonly property int cellSize: 40 * Config.scale
  }
  readonly property Calendar calendar: Calendar { }

  component Font: QtObject {
    readonly property string main: "CaskaydiaCove Nerd Font"
    readonly property string symbols: "Symbols Nerd Font"
    readonly property string light: "CaskaydiaCove Nerd Font Light"
    readonly property string extraLight: "CaskaydiaCove Nerd Font ExtraLight"
    readonly property int size0: 10 * Config.scale
    readonly property int size1: 12 * Config.scale
    readonly property int size2: 14 * Config.scale
    readonly property int size3: 16 * Config.scale
    readonly property int size4: 18 * Config.scale

    readonly property int normal: 10 * Config.scale
    readonly property int small: 9 * Config.scale
    readonly property int large: 12 * Config.scale
    readonly property int xl: 16 * Config.scale
    readonly property int tiny: 8 * Config.scale
  }
  readonly property Font font: Font {}

  component Spacing: QtObject {
    readonly property int p0: 3 * Config.scale
    readonly property int p1: 6 * Config.scale
    readonly property int p2: 8 * Config.scale
    readonly property int p3: 12 * Config.scale
    readonly property int p4: 16 * Config.scale
    readonly property int p5: 24 * Config.scale
  }
  readonly property Spacing spacing: Spacing { }

  component Durations: QtObject {
    readonly property int slow: 800
    readonly property int large: 500
    readonly property int normal: 400
    readonly property int medium: 300
    readonly property int small: 200
    readonly property int tiny: 100
  }
  readonly property Durations durations: Durations { }

  // https://github.com/end-4/dots-hyprland/blob/703697e1c40b66619fb224043891aade47494bb3/.config/quickshell/ii/modules/common/Appearance.qml#L225-L242
  component AnimationCurves: QtObject {
    readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
    readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
    readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
    readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
    readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> emphasizedFirstHalf: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82]
    readonly property list<real> emphasizedLastHalf: [5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
    readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    readonly property real expressiveFastSpatialDuration: 350
    readonly property real expressiveDefaultSpatialDuration: 500
    readonly property real expressiveSlowSpatialDuration: 650
    readonly property real expressiveEffectsDuration: 200
  }
  readonly property AnimationCurves animationCurves: AnimationCurves { }
}

