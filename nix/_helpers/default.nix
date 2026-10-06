# The helper binaries the shell shells out to; sources live in scripts/.
{
  pkgs,
  lib,
  gslapper,
  hyprland,
  lockCommand,
  wallpaperDir,
  defaultWallpaper,
  screenshotDir,
  sinks,
}: let
  script = import ./script.nix {inherit pkgs;};

  # Disables qalc's mixed-unit output and its automatic exchange-rate refresh.
  qalcConfig = pkgs.writeTextDir "qalculate/qalc.cfg" ''
    mixed_units_conversion=0
    update_exchange_rates=0
  '';

  calendarBackend = let
    # EDataServer-1.2.typelib depends on libxml2-2.0, which nixpkgs ships inside
    # gobject-introspection rather than libxml2 -- without it the import fails
    # with "Typelib file for namespace 'libxml2' not found".
    giPackages = with pkgs; [evolution-data-server libical libsoup_3 json-glib glib gobject-introspection];
    python = pkgs.python3.withPackages (ps: [ps.pygobject3 ps.parsedatetime]);
  in
    pkgs.runCommand "erebus-calendar-backend" {nativeBuildInputs = [pkgs.makeWrapper];} ''
      install -Dm755 ${../../scripts/erebus-calendar-backend.py} $out/bin/erebus-calendar-backend
      substituteInPlace $out/bin/erebus-calendar-backend \
        --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3'
      wrapProgram $out/bin/erebus-calendar-backend \
        --prefix GI_TYPELIB_PATH : "${lib.makeSearchPath "lib/girepository-1.0" giPackages}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath giPackages}"
    '';

  # One small JPEG per wallpaper at <rel>.jpg, for the launcher's picker cards.
  # Videos get a single frame. Built from the wallpaper root, so it only rebuilds
  # when that changes, and Qt never decodes a 4K original for a 300px card.
  thumbs = pkgs.runCommand "erebus-wallpaper-thumbs" {nativeBuildInputs = [pkgs.ffmpeg-headless];} ''
    mkdir -p $out
    cd ${wallpaperDir}
    find . -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
           -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) -print0 |
      while IFS= read -r -d "" f; do
        rel="''${f#./}"
        mkdir -p "$out/$(dirname "$rel")"
        case "''${rel,,}" in
          *.mp4|*.mkv|*.webm) seek="-ss 1" ;;
          *) seek="" ;;
        esac
        ffmpeg -nostdin -loglevel error $seek -i "$rel" -frames:v 1 \
          -vf scale=480:-2 -q:v 4 "$out/$rel.jpg"
      done
  '';
in rec {
  inherit calendarBackend;
  power = script "power" [pkgs.systemd hyprland] {EREBUS_LOCK_COMMAND = lockCommand;};
  screenshot = script "screenshot" (with pkgs; [grim slurp satty jq wl-clipboard coreutils hyprland]) {
    EREBUS_SCREENSHOT_DIR = screenshotDir;
  };
  colorpicker = script "colorpicker" (with pkgs; [hyprpicker libnotify]) {};
  audioSwitch = script "audio-switch" (with pkgs; [wireplumber pipewire jq coreutils libnotify]) {
    EREBUS_SINK_HEADPHONES = sinks.headphones;
    EREBUS_SINK_HEADSET = sinks.headset;
    EREBUS_SINK_HDMI = sinks.hdmi;
    EREBUS_SINK_SPDIF = sinks.spdif;
  };
  kbdBacklight = script "kbd-backlight" [pkgs.brightnessctl pkgs.coreutils hyprland] {};
  brightness = script "brightness" [pkgs.brightnessctl hyprland] {};
  clipboard = script "clipboard" (with pkgs; [cliphist wl-clipboard]) {};
  calc = script "calc" (with pkgs; [libqalculate wl-clipboard]) {EREBUS_QALC_CONFIG = "${qalcConfig}";};
  calendar = script "calendar" (with pkgs; [calendarBackend evolution gnome-calendar]) {};
  monitors = script "monitors" (with pkgs; [jq coreutils libnotify wdisplays hyprland]) {};
  wallpaper = script "wallpaper" (with pkgs; [jq procps findutils coreutils gnused gslapper hyprland]) {
    EREBUS_WALLPAPER_DIR = "${wallpaperDir}";
    EREBUS_WALLPAPER_DEFAULT = defaultWallpaper;
    EREBUS_WALLPAPER_THUMBS = "${thumbs}";
  };

  all = [power screenshot colorpicker audioSwitch kbdBacklight brightness clipboard calc calendar monitors wallpaper];
}
