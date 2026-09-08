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

    # Nudge the shell to re-read a value it cannot observe: sysfs gives no change
    # notification, so an OSD would otherwise never fire for a key the shell did
    # not press itself. hyprctl dispatch takes a lua expression as of 0.56 -- the
    # old `dispatch global quickshell:x` form is a parse error now. A name no
    # shell has registered still answers ok, which is the point: the key keeps
    # working with the bar dead.
    notify = name: "${hyprctl} dispatch 'hl.dsp.global(\"quickshell:${name}\")' >/dev/null 2>&1 || true";

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

    # Fn+Up/Down on the ASUS laptop emit KEY_KBDILLUM{UP,DOWN}; nothing in the
    # kernel acts on them, so the step has to happen here. The LED is named per
    # vendor (asus::kbd_backlight here, tpacpi::kbd_backlight on a ThinkPad) and
    # desktops have none at all, so glob for it and no-op quietly when absent --
    # this helper is in the shared profile, not a laptop-only module.
    #
    # brightnessctl needs no udev rule or setuid for this: with -c leds it goes
    # through logind's SetBrightness, which the active session is allowed to call.
    kbdBacklight = pkgs.writeShellScriptBin "erebus-kbd-backlight" ''
      set -eu
      led=""
      for d in /sys/class/leds/*kbd_backlight*; do
        [ -e "$d" ] || continue
        led=''${d##*/}
        break
      done
      [ -n "$led" ] || exit 0

      bctl="${pkgs.brightnessctl}/bin/brightnessctl -q -c leds -d $led"
      cur() { cat "/sys/class/leds/$led/brightness"; }

      case "''${1:-}" in
        # Steps are raw levels, not percentages: this backlight has 4 of them
        # (0-3), and brightnessctl clamps at both ends.
        up)     $bctl set +1 ;;
        down)   $bctl set 1- ;;
        toggle)
          if [ "$(cur)" -gt 0 ]; then $bctl set 0; else $bctl set 100%; fi ;;
        # What KbdBacklight.qml parses. sysfs, not brightnessctl -m, because the
        # LED name is already resolved here and the format stays ours.
        status) echo "$(cur) $(cat "/sys/class/leds/$led/max_brightness")"; exit 0 ;;
        *)
          echo "usage: erebus-kbd-backlight {up|down|toggle|status}" >&2
          exit 2 ;;
      esac

      ${notify "kbdBacklightChanged"}
    '';

    # The panel backlight. Same shape as above so both keys reach the OSD the
    # same way; -n stops 5%- at 1, since a black panel is indistinguishable from
    # a crashed session and can only be undone by feel.
    brightness = pkgs.writeShellScriptBin "erebus-brightness" ''
      set -eu
      bctl="${pkgs.brightnessctl}/bin/brightnessctl -q -c backlight"

      case "''${1:-}" in
        up)     $bctl set 5%+ ;;
        down)   $bctl -n set 5%- ;;
        status) exec ${pkgs.brightnessctl}/bin/brightnessctl -c backlight -m info ;;
        *)
          echo "usage: erebus-brightness {up|down|status}" >&2
          exit 2 ;;
      esac

      ${notify "brightnessChanged"}
    '';

  in {
    home.packages = [
      power
      screenshot
      colorpicker
      audioSwitch
      kbdBacklight
      brightness
    ];
  };
}
