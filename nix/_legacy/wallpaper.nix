# Wallpaper, backed by gSlapper. It is a drop-in mpvpaper replacement that plays
# both stills and video, so one backend covers berserk/*.jpg and animated/*.mp4.
#
# Noctalia's gSlapper plugin saved absolute /nix/store paths, which went stale on
# every rebuild and broke outright on GC -- that is what noctaliaRepointAssignments
# existed to sed around. Here the state file stores paths RELATIVE to the wallpaper
# root, resolved against the current root at apply time, so churn cannot break it.
{ self, inputs, ... }: {
  flake.homeModules.wallpaper = { pkgs, lib, ... }:
  let
    gslapper = "${inputs.gslapper.packages.${pkgs.stdenv.hostPlatform.system}.gslapper}/bin/gslapper";
    hyprctl = "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/hyprctl";
    root = "${self}/assets/backgrounds";
    # Fallback for any output with no saved choice -- otherwise a fresh login, or
    # a newly plugged-in monitor, comes up with no wallpaper at all.
    default = "animated/large-cherry-blossom-tree.1920x1080.mp4";

    wallpaper = pkgs.writeShellScriptBin "erebus-wallpaper" ''
      set -eu
      ROOT="${root}"
      DEFAULT="${default}"
      STATE="''${XDG_STATE_HOME:-$HOME/.local/state}/erebus"
      FILE="$STATE/wallpapers.json"
      SOCKDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/erebus-gslapper"
      jq=${pkgs.jq}/bin/jq
      mkdir -p "$STATE" "$SOCKDIR"
      [ -f "$FILE" ] || echo '{}' > "$FILE"

      _is_video() { case "''${1,,}" in *.mp4|*.mkv|*.webm|*.avi|*.mov) return 0 ;; *) return 1 ;; esac; }

      # Relative paths only, so a new store path or a GC cannot invalidate state.
      _list() { ( cd "$ROOT" && find . -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
             -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) \
          | sed 's|^\./||' | sort ); }

      _outputs() { ${hyprctl} -j monitors | $jq -r '.[].name'; }

      _apply() {
        out="$1"; rel="$2"
        abs="$ROOT/$rel"
        if [ ! -f "$abs" ]; then
          echo "erebus-wallpaper: missing $rel under $ROOT" >&2
          return 1
        fi
        # One gslapper per output. Kill by recorded PID, not `pkill -f`: the
        # pattern would also match any shell whose command line happens to
        # contain it (including the one invoking this script).
        pidfile="$SOCKDIR/$out.pid"
        if [ -f "$pidfile" ]; then
          oldpid=$(cat "$pidfile" 2>/dev/null || true)
          if [ -n "$oldpid" ] && [ -d "/proc/$oldpid" ]; then
            case "$(tr '\0' ' ' < "/proc/$oldpid/cmdline" 2>/dev/null)" in
              *"erebus-gslapper/$out.sock"*) kill "$oldpid" 2>/dev/null || true ;;
            esac
          fi
          rm -f "$pidfile"
        fi
        if _is_video "$rel"; then
          opts="fill no-audio loop"
        else
          opts="fill"
        fi
        ${gslapper} --fork --no-save-state \
          --ipc-socket "$SOCKDIR/$out.sock" \
          --gst-options "$opts" --fps-cap 60 \
          "$out" "$abs" >/dev/null 2>&1 || true
        # --fork detaches, so find the child we just started by its socket path.
        for cand in $(${pkgs.procps}/bin/pgrep -f 'gslapper' 2>/dev/null || true); do
          case "$(tr '\0' ' ' < "/proc/$cand/cmdline" 2>/dev/null)" in
            *"erebus-gslapper/$out.sock"*) echo "$cand" > "$SOCKDIR/$out.pid" ;;
          esac
        done
      }

      _save() {
        out="$1"; rel="$2"
        tmp=$(mktemp)
        $jq --arg o "$out" --arg p "$rel" '.[$o] = $p' "$FILE" > "$tmp" && mv "$tmp" "$FILE"
      }

      case "''${1:-}" in
        root) echo "$ROOT" ;;
        list) _list ;;
        outputs) _outputs ;;
        current)
          $jq -r --arg o "''${2:-}" '.[$o] // ""' "$FILE" ;;
        state) cat "$FILE" ;;
        set)
          [ $# -ge 3 ] || { echo "usage: erebus-wallpaper set <output> <relative-path>" >&2; exit 2; }
          _apply "$2" "$3" && _save "$2" "$3" ;;
        set-all)
          [ $# -ge 2 ] || { echo "usage: erebus-wallpaper set-all <relative-path>" >&2; exit 2; }
          for o in $(_outputs); do _apply "$o" "$2" && _save "$o" "$2"; done ;;
        restore)
          # Applied at login and after a rebuild; resolves stored relative paths
          # against whatever the current root is. Outputs with no saved choice
          # fall back to DEFAULT so every screen always has a wallpaper.
          for o in $(_outputs); do
            rel=$($jq -r --arg o "$o" '.[$o] // ""' "$FILE")
            if [ -z "$rel" ]; then rel="$DEFAULT"; fi
            _apply "$o" "$rel" && _save "$o" "$rel" || true
          done ;;
        *)
          echo "usage: erebus-wallpaper {list|outputs|current <out>|state|set <out> <rel>|set-all <rel>|restore|root}" >&2
          exit 2 ;;
      esac
    '';
  in {
    home.packages = [
      wallpaper
      inputs.gslapper.packages.${pkgs.stdenv.hostPlatform.system}.gslapper
      pkgs.jq
    ];
  };
}
