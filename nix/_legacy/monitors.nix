# Monitor management. Replaces the noctalia hypr-screen-mirror plugin panel and
# the rofi-based hypr-mirror-toggle.
#
# IMPORTANT: this Hyprland runs a *Lua* config (hyprland.nix sets configType =
# "lua"), which replaces hyprlang's keyword system entirely -- `hyprctl keyword`
# answers "unknown request" for every key, monitors included. Runtime changes have
# to go through `hyprctl eval` and the Lua `hl.monitor{}` API instead. (The same
# reason wdisplays.nix's hypr-mirror-toggle and noctalia's hypr-extra hook have
# been silently no-ops on this machine.)
#
# Two further quirks, found by testing:
#   * a mirrored output drops out of `hyprctl monitors` entirely, so listing has
#     to use `monitors all`;
#   * clearing a mirror needs an explicit mirror = "none" -- omitting the key
#     leaves the output mirrored.
{ self, inputs, ... }: {
  flake.homeModules.monitors = { pkgs, lib, ... }:
  let
    hyprctl = "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/hyprctl";

    monitors = pkgs.writeShellScriptBin "erebus-monitors" ''
      set -eu
      jq=${pkgs.jq}/bin/jq
      hyprctl=${hyprctl}
      STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/erebus"
      MIRRORS="$STATE/monitors.json"
      mkdir -p "$STATE"
      [ -f "$MIRRORS" ] || echo '{}' > "$MIRRORS"

      _all() { $hyprctl -j monitors all; }

      _eval() {
        out=$($hyprctl eval "$1" 2>&1 || true)
        case "$out" in
          ok*) return 0 ;;
          *) echo "erebus-monitors: hyprctl eval failed: $out" >&2; return 1 ;;
        esac
      }

      # name \t description \t WxH@Hz \t XxY \t scale \t enabled|disabled \t mirrorOf \t focused
      _list() {
        _all | $jq -r '.[] | [
          .name,
          (.description // "" | split(" (")[0]),
          ((.width|tostring) + "x" + (.height|tostring) + "@" + ((.refreshRate // 0)|floor|tostring)),
          ((.x|tostring) + "x" + (.y|tostring)),
          ((.scale // 1)|tostring),
          (if .disabled then "disabled" else "enabled" end),
          (if (.mirrorOf // "none") == "none" then "none" else "yes" end),
          (if .focused then "focused" else "-" end)
        ] | @tsv'
      }

      # Remember real geometry so unmirror/enable can put it back exactly.
      _save_geom() {
        g=$(_all | $jq -r --arg n "$1" \
          '.[] | select(.name == $n and (.mirrorOf // "none") == "none" and (.disabled | not))
           | ((.width|tostring) + "x" + (.height|tostring) + "@" + (.refreshRate|tostring))
             + "|" + ((.x|tostring) + "x" + (.y|tostring)) + "|" + ((.scale // 1)|tostring)')
        [ -n "$g" ] || return 0
        tmp=$(mktemp)
        $jq --arg o "$1" --arg g "$g" '.[$o] = $g' "$MIRRORS" > "$tmp" && mv "$tmp" "$MIRRORS"
      }

      _restore_geom() {
        saved=$($jq -r --arg o "$1" '.[$o] // ""' "$MIRRORS")
        if [ -n "$saved" ]; then
          mode=''${saved%%|*}; rest=''${saved#*|}
          pos=''${rest%%|*}; scale=''${rest##*|}
        else
          mode="preferred"; pos="auto"; scale="1"
        fi
        # disabled = false is required: hl.monitor leaves an output off unless the
        # flag is cleared explicitly, so re-enabling silently no-ops without it.
        _eval "hl.monitor({ output = \"$1\", disabled = false, mode = \"$mode\", position = \"$pos\", scale = $scale, mirror = \"none\" })"
        tmp=$(mktemp); $jq --arg o "$1" 'del(.[$o])' "$MIRRORS" > "$tmp" && mv "$tmp" "$MIRRORS"
      }

      case "''${1:-list}" in
        list) _list ;;
        json) _all ;;
        arrange) exec ${pkgs.wdisplays}/bin/wdisplays ;;
        save)    exec hypr-save-monitors ;;

        enable)
          [ $# -ge 2 ] || { echo "usage: erebus-monitors enable <output>" >&2; exit 2; }
          _restore_geom "$2" ;;

        disable)
          [ $# -ge 2 ] || { echo "usage: erebus-monitors disable <output>" >&2; exit 2; }
          n=$(_all | $jq '[.[] | select(.disabled | not)] | length')
          if [ "$n" -le 1 ]; then
            ${pkgs.libnotify}/bin/notify-send -u critical "Display" "Refusing to disable the only active monitor"
            exit 1
          fi
          _save_geom "$2"
          _eval "hl.monitor({ output = \"$2\", disabled = true })" ;;

        toggle)
          [ $# -ge 2 ] || { echo "usage: erebus-monitors toggle <output>" >&2; exit 2; }
          d=$(_all | $jq -r --arg n "$2" '.[] | select(.name == $n) | .disabled')
          if [ "$d" = "true" ]; then exec "$0" enable "$2"; else exec "$0" disable "$2"; fi ;;

        mirror)
          [ $# -ge 3 ] || { echo "usage: erebus-monitors mirror <source> <target>" >&2; exit 2; }
          _save_geom "$3"
          _eval "hl.monitor({ output = \"$3\", disabled = false, mode = \"preferred\", position = \"auto\", scale = 1, mirror = \"$2\" })"
          ${pkgs.libnotify}/bin/notify-send -u low -t 3000 "Display" "$2  →  $3  (mirrored)" ;;

        unmirror)
          [ $# -ge 2 ] || { echo "usage: erebus-monitors unmirror <output>" >&2; exit 2; }
          _restore_geom "$2"
          ${pkgs.libnotify}/bin/notify-send -u low -t 3000 "Display" "$2 restored to extended mode" ;;

        *)
          echo "usage: erebus-monitors {list|json|arrange|save|enable <o>|disable <o>|toggle <o>|mirror <src> <dst>|unmirror <o>}" >&2
          exit 2 ;;
      esac
    '';
  in {
    home.packages = [ monitors ];
  };
}
