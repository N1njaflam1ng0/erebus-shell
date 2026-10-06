# qalc exposes no command-line switch for mixed-unit output -- without this
# "5 km to miles" comes back as "3 mi + 188 yd + 2.393700787 in". The only knob
# is a config key, so point XDG_CONFIG_HOME at a store copy rather than the
# user's own ~/.config/qalculate. Exchange rates live under XDG_DATA_HOME.
export XDG_CONFIG_HOME="$EREBUS_QALC_CONFIG"

case "${1:-}" in
  eval)
    [ $# -ge 2 ] || exit 0
    # -m caps a runaway expression so the launcher can never hang on one.
    # A failed parse prints nothing and still exits 0: services/LauncherData.qml
    # reads empty stdout as "not maths" and shows no card.
    qalc -t -m 2000 "$2" 2>/dev/null || exit 0 ;;
  copy)
    # Takes the result on argv, so the caller never has to re-quote it.
    [ $# -ge 2 ] || { echo "usage: erebus-calc copy <text>" >&2; exit 2; }
    printf '%s' "$2" | wl-copy ;;
  update-rates)
    # update_exchange_rates=0 only disables the automatic refresh; this is the
    # manual one.
    exec qalc -e ;;
  *)
    echo "usage: erebus-calc {eval <expr>|copy <text>|update-rates}" >&2
    exit 2 ;;
esac
