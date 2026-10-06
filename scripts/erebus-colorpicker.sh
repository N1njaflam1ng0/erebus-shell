# hyprpicker -a already copies to the clipboard; notify so there's feedback.
color=$(hyprpicker -a -f hex) || exit 0
[ -n "$color" ] || exit 0
notify-send -u low -t 3000 "Colour picked" "$color"
