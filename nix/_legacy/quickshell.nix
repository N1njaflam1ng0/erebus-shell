# The Quickshell desktop shell. QML source is vendored in assets/quickshell/
# (adapted from roosta/dotfiles, GPLv3); this module pins the host-specific values
# into config/Host.qml and runs the result straight out of the store.
{ self, inputs, ... }: {
  flake.homeModules.quickshell = { pkgs, lib, config, ... }:
  let
    cfg = config.erebus.shell;
    system = pkgs.stdenv.hostPlatform.system;
    hyprctl = "${inputs.hyprland.packages.${system}.hyprland}/bin/hyprctl";

    # Generated counterpart to the checked-in assets/quickshell/config/Host.qml.
    # The checked-in copy uses bare binary names so `qs -p assets/quickshell` works
    # in a dev shell; this one pins absolute store paths and the real outputs.
    hostQml = pkgs.writeText "Host.qml" ''
      // GENERATED — see modules/features/desktop/quickshell/quickshell.nix
      pragma Singleton
      import Quickshell

      Singleton {
        id: root

        readonly property string primary: "${cfg.primary}"
        readonly property string left: "${cfg.left}"
        readonly property string right: "${cfg.right}"

        readonly property var outputs: [${lib.concatMapStringsSep ", " (o: "\"${o}\"") cfg.outputs}]

        readonly property string terminal: "${cfg.terminal}"

        readonly property string power: "erebus-power"
        readonly property string screenshot: "erebus-screenshot"
        readonly property string colorpicker: "erebus-colorpicker"
        readonly property string audioSwitch: "erebus-audio-switch"
        readonly property string monitors: "erebus-monitors"
        readonly property string clipboard: "erebus-clipboard"
        readonly property string wallpaper: "erebus-wallpaper"
        readonly property string calendar: "erebus-calendar"
        readonly property string brightnessctl: "${pkgs.brightnessctl}/bin/brightnessctl"
        readonly property string sysmon: "${pkgs.btop}/bin/btop"
        readonly property string cava: "${pkgs.cava}/bin/cava"
        readonly property string hyprctl: "${hyprctl}"

        readonly property string sinkHeadphones: "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headphones__sink"
        readonly property string sinkHeadset: "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headset__sink"
        readonly property string sinkHdmi: "alsa_output.pci-0000_01_00.1.hdmi-stereo"
        readonly property string sinkSpdif: "alsa_output.pci-0000_00_1f.3.iec958-stereo"
      }
    '';

    shellSrc = pkgs.runCommand "erebus-shell-src" { } ''
      cp -r ${self}/assets/quickshell $out
      chmod -R u+w $out
      cp ${hostQml} $out/config/Host.qml
    '';

    # `qs -p <dir>` takes any path, so the shell runs from the store the same way
    # the noctalia config did — no ~/.config copy to drift out of sync.
    launcher = pkgs.writeShellScriptBin "erebus-shell" ''
      # Qt6 resolves icon names through qt6ct, but the session-wide value is
      # qt5ct, which leaves this process with no icon theme at all and renders
      # blank tiles in the tray and launcher.
      export QT_QPA_PLATFORMTHEME=qt6ct

      # The erebus-* helpers are plain home.packages, so Host.qml names them
      # bare and they resolve via PATH. That holds when Hyprland launches this
      # from the user session, but not from a minimal environment (a systemd
      # user unit, say) -- so make the profile explicit rather than assumed.
      export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$PATH"

      exec ${pkgs.quickshell}/bin/quickshell -p ${shellSrc} "$@"
    '';
  in {
    options.erebus.shell = {
      primary = lib.mkOption {
        type = lib.types.str;
        default = "DP-1";
        description = "Output that gets the primary bar layout and the notification toasts.";
      };
      left = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Output in the 'left' role, or \"\" if this host has none.";
      };
      right = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Output in the 'right' role, or \"\" if this host has none.";
      };
      outputs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Every output the shell knows about. Bars are drawn on all connected outputs regardless.";
      };
      terminal = lib.mkOption {
        type = lib.types.str;
        default = "ghostty";
        description = "Terminal the launcher uses for run-in-terminal entries.";
      };
    };

    config = {
      home.packages = [
        pkgs.quickshell
        pkgs.cava
        pkgs.brightnessctl
        launcher
      ];

      # Feeds the bar's audio visualiser. `raw` output on stdout is what
      # services/AudioData.qml parses.
      xdg.configFile."cava/erebus.ini".text = ''
        ; Mirrors roosta's ritual.ini. ascii/raw on stdout is what
        ; services/AudioData.qml reads, and ascii_max_range must stay 100
        ; because that parser divides each value by 100.
        [general]
        bars = 128

        [output]
        method = raw
        channels = stereo
        data_format = ascii
        ascii_max_range = 100
      '';
    };
  };
}
