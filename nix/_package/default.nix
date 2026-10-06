# shell/ with a generated Host.qml, run from the store as `erebus-shell`.
{
  pkgs,
  lib,
  helpers,
  hyprland,
  outputs,
  terminal,
  sinks,
}: let
  exe = lib.getExe;

  # Generated counterpart to the checked-in shell/config/Host.qml. The checked-in
  # copy uses bare binary names so `qs -p shell` works in `nix develop`; this one
  # pins absolute store paths and the configured outputs.
  hostQml = pkgs.writeText "Host.qml" ''
    // GENERATED -- see nix/_package/default.nix
    pragma Singleton
    import Quickshell

    Singleton {
      id: root

      readonly property string primary: "${outputs.primary}"
      readonly property string left: "${outputs.left}"
      readonly property string right: "${outputs.right}"

      readonly property string terminal: "${terminal}"

      readonly property string power: "${exe helpers.power}"
      readonly property string screenshot: "${exe helpers.screenshot}"
      readonly property string colorpicker: "${exe helpers.colorpicker}"
      readonly property string audioSwitch: "${exe helpers.audioSwitch}"
      readonly property string monitors: "${exe helpers.monitors}"
      readonly property string clipboard: "${exe helpers.clipboard}"
      readonly property string wallpaper: "${exe helpers.wallpaper}"
      readonly property string calendar: "${exe helpers.calendar}"
      readonly property string calc: "${exe helpers.calc}"
      readonly property string brightnessctl: "${pkgs.brightnessctl}/bin/brightnessctl"
      readonly property string kbdBacklight: "${exe helpers.kbdBacklight}"
      readonly property string sysmon: "${pkgs.btop}/bin/btop"
      readonly property string cava: "${pkgs.cava}/bin/cava"
      readonly property string hyprctl: "${hyprland}/bin/hyprctl"
      readonly property string hcitool: "${pkgs.bluez}/bin/hcitool"

      readonly property string sinkHeadphones: "${sinks.headphones}"
      readonly property string sinkHeadset: "${sinks.headset}"
      readonly property string sinkHdmi: "${sinks.hdmi}"
      readonly property string sinkSpdif: "${sinks.spdif}"
    }
  '';

  src = pkgs.runCommand "erebus-shell-src" {} ''
    cp -r ${../../shell} $out
    chmod -R u+w $out
    cp ${hostQml} $out/config/Host.qml

    # A new QML file that was never `git add`ed is silently absent from the
    # flake source, and the shell then fails to load outright ("module qs.X is
    # not installed") with nothing else reporting it. Fail the build instead.
    # Only catches a missing directory; `git add` before a rebuild is still the
    # real guard.
    missing=0
    for mod in $(grep -rhoE '^import qs\.[A-Za-z0-9_.]+' $out --include='*.qml' \
                 | sed 's/^import qs\.//' | sort -u); do
      if [ ! -d "$out/$(echo "$mod" | tr . /)" ]; then
        echo "erebus-shell: unresolvable QML import: qs.$mod (git add?)" >&2
        missing=1
      fi
    done
    [ $missing -eq 0 ]
  '';
in
  pkgs.writeShellApplication {
    name = "erebus-shell";
    # Qt6 resolves icon names through qt6ct, but the session-wide value is
    # qt5ct, which leaves this process with no icon theme at all and renders
    # blank tiles in the tray and launcher.
    runtimeEnv.QT_QPA_PLATFORMTHEME = "qt6ct";
    text = ''
      exec ${pkgs.quickshell}/bin/quickshell -p ${src} "$@"
    '';
  }
