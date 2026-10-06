case "${1:-}" in
  events)
    [ $# -eq 3 ] || { echo "usage: erebus-calendar events <start> <end>" >&2; exit 2; }
    # An empty array plus a non-zero exit is how services/Calendar.qml tells
    # "no account set up yet" apart from "this month is empty".
    erebus-calendar-backend events "$2" "$3" || { echo "[]"; exit 1; }
    ;;
  add)
    [ $# -eq 2 ] || { echo "usage: erebus-calendar add <text>" >&2; exit 2; }
    exec erebus-calendar-backend add "$2" ;;
  calendars)
    exec erebus-calendar-backend calendars ;;
  auth)
    # Evolution is the account UI: it runs Google's OAuth flow against EDS's
    # built-in credentials. Add the account with
    #   File -> New -> Collection Account
    # then enter the Gmail address, sign in, and untick everything except
    # Calendar unless you want the mail set up too.
    #
    # -c calendar opens on the Calendar view rather than Mail. There is an
    # evolution://new-collection-account URI that the first-run wizard links
    # to, but --view refuses it and exits, so the menu is the way in.
    exec evolution -c calendar ;;
  open)
    exec gnome-calendar ;;
  *)
    echo "usage: erebus-calendar {events <start> <end>|add <text>|calendars|auth|open}" >&2
    exit 2 ;;
esac
