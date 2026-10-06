# grim into satty for annotation. Region uses slurp; output grabs the focused
# monitor, which hyprctl reports as `focused: yes`.
out="$EREBUS_SCREENSHOT_DIR"
mkdir -p "$out"
file="$out/$(date +%Y-%m-%d_%H-%M-%S).png"
case "${1:-region}" in
  region)
    geom=$(slurp) || exit 0
    grim -g "$geom" - ;;
  output)
    mon=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
    grim -o "$mon" - ;;
  *)
    echo "usage: erebus-screenshot {region|output}" >&2; exit 2 ;;
esac | satty --filename - --output-filename "$file" --early-exit --copy-command wl-copy
