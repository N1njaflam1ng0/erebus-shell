case "${1:-}" in
  shutdown)  exec systemctl poweroff ;;
  reboot)    exec systemctl reboot ;;
  suspend)   exec systemctl suspend ;;
  hibernate) exec systemctl hibernate ;;
  # The lock command is a string option, so it may carry its own arguments.
  lock)      exec sh -c "$EREBUS_LOCK_COMMAND" ;;
  # hyprctl dispatch takes a Lua expression as of 0.56; bare `exit` no longer parses.
  logout)    exec hyprctl dispatch 'hl.dsp.exit()' ;;
  *)
    echo "usage: erebus-power {shutdown|reboot|suspend|hibernate|lock|logout}" >&2
    exit 2 ;;
esac
