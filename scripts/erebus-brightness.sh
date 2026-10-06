# The panel backlight. Same shape as erebus-kbd-backlight so both keys reach the
# OSD the same way.
case "${1:-}" in
  up)     brightnessctl -q -c backlight set 5%+ ;;
  # -n stops at 1: a black panel is indistinguishable from a crashed session.
  down)   brightnessctl -q -c backlight -n set 5%- ;;
  status) exec brightnessctl -c backlight -m info ;;
  *)
    echo "usage: erebus-brightness {up|down|status}" >&2
    exit 2 ;;
esac

# sysfs has no change events; tell the OSD to re-read.
hyprctl dispatch 'hl.dsp.global("quickshell:brightnessChanged")' >/dev/null 2>&1 || true
