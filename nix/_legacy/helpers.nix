# The helper binaries the shell shells out to. roosta's config calls ~/scripts/*.sh
# from a submodule that isn't vendored and is written for his Arch host, so these
# are Nix-native equivalents following the repo's writeShellScriptBin idiom
# (see wdisplays.nix, search.nix).
{ inputs, ... }: {
  flake.homeModules.quickshell-helpers = { pkgs, lib, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    hyprctl = "${inputs.hyprland.packages.${system}.hyprland}/bin/hyprctl";
    qylock = inputs.qylock.packages.${system}.qylock-quickshell;

    power = pkgs.writeShellScriptBin "erebus-power" ''
      set -eu
      case "''${1:-}" in
        shutdown)  exec ${pkgs.systemd}/bin/systemctl poweroff ;;
        reboot)    exec ${pkgs.systemd}/bin/systemctl reboot ;;
        suspend)   exec ${pkgs.systemd}/bin/systemctl suspend ;;
        hibernate) exec ${pkgs.systemd}/bin/systemctl hibernate ;;
        lock)      exec ${qylock}/bin/qylock-lock ;;
        logout)    exec ${hyprctl} dispatch exit ;;
        *)
          echo "usage: erebus-power {shutdown|reboot|suspend|hibernate|lock|logout}" >&2
          exit 2 ;;
      esac
    '';

    # grim into satty for annotation. Region uses slurp; output grabs the focused
    # monitor, which hyprctl reports as `focused: yes`.
    screenshot = pkgs.writeShellScriptBin "erebus-screenshot" ''
      set -eu
      out="$HOME/Pictures/screenshots"
      mkdir -p "$out"
      file="$out/$(date +%Y-%m-%d_%H-%M-%S).png"
      case "''${1:-region}" in
        region)
          geom=$(${pkgs.slurp}/bin/slurp) || exit 0
          ${pkgs.grim}/bin/grim -g "$geom" - ;;
        output)
          mon=$(${hyprctl} -j monitors | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
          ${pkgs.grim}/bin/grim -o "$mon" - ;;
        *)
          echo "usage: erebus-screenshot {region|output}" >&2; exit 2 ;;
      esac | ${pkgs.satty}/bin/satty --filename - --output-filename "$file" --early-exit --copy-command ${pkgs.wl-clipboard}/bin/wl-copy
    '';

    # hyprpicker -a already copies to the clipboard; notify so there's feedback.
    colorpicker = pkgs.writeShellScriptBin "erebus-colorpicker" ''
      set -eu
      color=$(${pkgs.hyprpicker}/bin/hyprpicker -a -f hex) || exit 0
      [ -n "$color" ] || exit 0
      ${pkgs.libnotify}/bin/notify-send -u low -t 3000 "Colour picked" "$color"
    '';

    audioSwitch = pkgs.writeShellScriptBin "erebus-audio-switch" ''
      set -eu
      wpctl=${pkgs.wireplumber}/bin/wpctl
      # Resolve a PipeWire node name to its numeric id; wpctl only takes ids.
      _id() {
        ${pkgs.wireplumber}/bin/wpctl status --name 2>/dev/null | true
        ${pkgs.pipewire}/bin/pw-dump 2>/dev/null \
          | ${pkgs.jq}/bin/jq -r --arg n "$1" \
              '.[] | select(.info.props."node.name" == $n) | .id' \
          | head -1
      }
      _set() {
        id=$(_id "$1")
        if [ -z "$id" ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "Audio" "Sink not present: $1"
          exit 1
        fi
        $wpctl set-default "$id"
      }
      case "''${1:-}" in
        headphones)  _set "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headphones__sink" ;;
        headset)     _set "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headset__sink" ;;
        hdmi)        _set "alsa_output.pci-0000_01_00.1.hdmi-stereo" ;;
        spdif)       _set "alsa_output.pci-0000_00_1f.3.iec958-stereo" ;;
        mute-output) exec $wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        mute-input)  exec $wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
        *)
          echo "usage: erebus-audio-switch {headphones|headset|hdmi|spdif|mute-output|mute-input}" >&2
          exit 2 ;;
      esac
    '';

  in {
    home.packages = [
      power
      screenshot
      colorpicker
      audioSwitch
    ];
  };
}
