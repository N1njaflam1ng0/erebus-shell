# Wallpaper, backed by gSlapper: one backend for both stills and video.
#
# The state file stores paths RELATIVE to the wallpaper root, resolved against
# the current root at apply time, so a new store path or a GC cannot break it.
ROOT="$EREBUS_WALLPAPER_DIR"
DEFAULT="$EREBUS_WALLPAPER_DEFAULT"
THUMBS="$EREBUS_WALLPAPER_THUMBS"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/erebus"
FILE="$STATE/wallpapers.json"
SOCKDIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/erebus-gslapper"
mkdir -p "$STATE" "$SOCKDIR"
[ -f "$FILE" ] || echo '{}' > "$FILE"

_is_video() { case "${1,,}" in *.mp4|*.mkv|*.webm|*.avi|*.mov) return 0 ;; *) return 1 ;; esac; }

# Each line is "<rel>\t<thumbnail>"; the thumbnail is only ever read live.
_list() { ( cd "$ROOT" && find . -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
       -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) \
    | sed 's|^\./||' | sort \
    | while IFS= read -r rel; do printf '%s\t%s\n' "$rel" "$THUMBS/$rel.jpg"; done ); }

_outputs() { hyprctl -j monitors | jq -r '.[].name'; }

_apply() {
  out="$1"; rel="$2"
  abs="$ROOT/$rel"
  if [ ! -f "$abs" ]; then
    echo "erebus-wallpaper: missing $rel under $ROOT" >&2
    return 1
  fi
  # One gslapper per output. Kill by recorded PID, not `pkill -f`: the pattern
  # would also match any shell whose command line happens to contain it
  # (including the one invoking this script).
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
  gslapper --fork --no-save-state \
    --ipc-socket "$SOCKDIR/$out.sock" \
    --gst-options "$opts" --fps-cap 60 \
    "$out" "$abs" >/dev/null 2>&1 || true
  # --fork detaches, so find the child we just started by its socket path.
  for cand in $(pgrep -f 'gslapper' 2>/dev/null || true); do
    case "$(tr '\0' ' ' < "/proc/$cand/cmdline" 2>/dev/null || true)" in
      *"erebus-gslapper/$out.sock"*) echo "$cand" > "$SOCKDIR/$out.pid" ;;
    esac
  done
}

_save() {
  out="$1"; rel="$2"
  tmp=$(mktemp)
  jq --arg o "$out" --arg p "$rel" '.[$o] = $p' "$FILE" > "$tmp" && mv "$tmp" "$FILE"
}

case "${1:-}" in
  root) echo "$ROOT" ;;
  list) _list ;;
  outputs) _outputs ;;
  current)
    jq -r --arg o "${2:-}" '.[$o] // ""' "$FILE" ;;
  state) cat "$FILE" ;;
  set)
    [ $# -ge 3 ] || { echo "usage: erebus-wallpaper set <output> <relative-path>" >&2; exit 2; }
    _apply "$2" "$3" && _save "$2" "$3" ;;
  set-all)
    [ $# -ge 2 ] || { echo "usage: erebus-wallpaper set-all <relative-path>" >&2; exit 2; }
    for o in $(_outputs); do _apply "$o" "$2" && _save "$o" "$2"; done ;;
  restore)
    # Applied at login and after a rebuild. Outputs with no saved choice fall
    # back to DEFAULT so every screen always has a wallpaper.
    for o in $(_outputs); do
      rel=$(jq -r --arg o "$o" '.[$o] // ""' "$FILE")
      if [ -z "$rel" ]; then rel="$DEFAULT"; fi
      [ -n "$rel" ] || continue
      _apply "$o" "$rel" && _save "$o" "$rel" || true
    done ;;
  *)
    echo "usage: erebus-wallpaper {list|outputs|current <out>|state|set <out> <rel>|set-all <rel>|restore|root}" >&2
    exit 2 ;;
esac
