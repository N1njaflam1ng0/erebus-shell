# Resolve a PipeWire node name to its numeric id; wpctl only takes ids.
_id() {
  pw-dump 2>/dev/null \
    | jq -r --arg n "$1" '.[] | select(.info.props."node.name" == $n) | .id' \
    | head -1
}
_set() {
  id=$(_id "$1" || true)
  if [ -z "$id" ]; then
    notify-send -u critical "Audio" "Sink not present: $1"
    exit 1
  fi
  wpctl set-default "$id"
}
case "${1:-}" in
  headphones)  _set "$EREBUS_SINK_HEADPHONES" ;;
  headset)     _set "$EREBUS_SINK_HEADSET" ;;
  hdmi)        _set "$EREBUS_SINK_HDMI" ;;
  spdif)       _set "$EREBUS_SINK_SPDIF" ;;
  mute-output) exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  mute-input)  exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  *)
    echo "usage: erebus-audio-switch {headphones|headset|hdmi|spdif|mute-output|mute-input}" >&2
    exit 2 ;;
esac
