# Fn+Up/Down on the ASUS laptop emit KEY_KBDILLUM{UP,DOWN}; nothing in the
# kernel acts on them, so the step has to happen here. The LED is named per
# vendor (asus::kbd_backlight here, tpacpi::kbd_backlight on a ThinkPad) and
# desktops have none at all, so glob for it and no-op quietly when absent.
#
# brightnessctl needs no udev rule or setuid for this: with -c leds it goes
# through logind's SetBrightness, which the active session is allowed to call.
led=""
for d in /sys/class/leds/*kbd_backlight*; do
  [ -e "$d" ] || continue
  led=${d##*/}
  break
done
[ -n "$led" ] || exit 0

bctl() { brightnessctl -q -c leds -d "$led" "$@"; }
cur() { cat "/sys/class/leds/$led/brightness"; }

case "${1:-}" in
  # Steps are raw levels, not percentages: this backlight has 4 of them
  # (0-3), and brightnessctl clamps at both ends.
  up)     bctl set +1 ;;
  down)   bctl set 1- ;;
  toggle)
    if [ "$(cur)" -gt 0 ]; then bctl set 0; else bctl set 100%; fi ;;
  # What KbdBacklight.qml parses. sysfs, not brightnessctl -m, because the
  # LED name is already resolved here and the format stays ours.
  status) echo "$(cur) $(cat "/sys/class/leds/$led/max_brightness")"; exit 0 ;;
  *)
    echo "usage: erebus-kbd-backlight {up|down|toggle|status}" >&2
    exit 2 ;;
esac

# sysfs has no change events; tell the OSD to re-read. A name no shell has
# registered still answers ok, so the key keeps working with the bar dead.
hyprctl dispatch 'hl.dsp.global("quickshell:kbdBacklightChanged")' >/dev/null 2>&1 || true
