# Picker front-end for cliphist. The daemon (services.cliphist) is the
# consumer's; this only reads and edits its history.
# cliphist stores entries as "<id>\t<preview>". The id is what decode wants.
case "${1:-list}" in
  list)
    exec cliphist list ;;
  copy)
    # Takes an id on argv so the caller never has to re-quote the preview.
    [ $# -ge 2 ] || { echo "usage: erebus-clipboard copy <id>" >&2; exit 2; }
    printf '%s\t' "$2" | cliphist decode | wl-copy ;;
  delete)
    [ $# -ge 2 ] || { echo "usage: erebus-clipboard delete <id>" >&2; exit 2; }
    printf '%s\t' "$2" | cliphist delete ;;
  wipe)
    exec cliphist wipe ;;
  *)
    echo "usage: erebus-clipboard {list|copy <id>|delete <id>|wipe}" >&2
    exit 2 ;;
esac
