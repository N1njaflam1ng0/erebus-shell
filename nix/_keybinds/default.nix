# The keybinds the shell owns. One list renders both the Hyprland binds and a
# JSON cheat sheet, so the two cannot drift apart.
{lib}: let
  # A global shortcut the shell registers (shell.qml and the panels).
  shortcut = keys: name: label: {
    inherit keys label;
    shortcut = name;
  };
  command = keys: cmd: label: {
    inherit keys label;
    command = cmd;
  };
in {
  # MOD stands for the configured modifier.
  defaults = [
    (command "MOD + SHIFT + S" "erebus-screenshot region" "Screenshot a region")
    (shortcut "MOD + U" "togglePower" "Power menu")
    (shortcut "MOD + V" "toggleClipboard" "Clipboard history")
    (shortcut "MOD + B" "toggleBitwarden" "Bitwarden")
    (shortcut "MOD + W" "toggleWallpaper" "Wallpapers")
    (shortcut "MOD + N" "toggleWifi" "Wi-Fi")
    (shortcut "MOD + I" "toggleSystem" "System panel")
    (shortcut "MOD + R" "toggleLauncher" "Launcher")
    (shortcut "ALT + Space" "toggleLauncher" "Launcher")
    (shortcut "MOD + Grave" "toggleMenu" "Menu")
    (shortcut "MOD + Home" "toggleNotifications" "Notifications")
    (shortcut "MOD + BackSpace" "discardLastNotification" "Dismiss the last notification")
    (command "MOD + L" "erebus-power lock" "Lock")
    (shortcut "MOD + P" "toggleDisplays" "Displays")
    (command "MOD + SHIFT + M" "erebus-monitors arrange" "Arrange displays")
    # Keysyms, not Fn combos: Hyprland can't see Fn itself. They go through the
    # helpers rather than hl.dsp.global so brightness still works with the bar
    # dead; the helpers then nudge the OSD.
    ((command "XF86MonBrightnessUp" "erebus-brightness up" "Screen brightness up") // {repeating = true;})
    ((command "XF86MonBrightnessDown" "erebus-brightness down" "Screen brightness down") // {repeating = true;})
    ((command "XF86KbdBrightnessUp" "erebus-kbd-backlight up" "Keyboard backlight up") // {repeating = true;})
    ((command "XF86KbdBrightnessDown" "erebus-kbd-backlight down" "Keyboard backlight down") // {repeating = true;})
    (command "XF86KbdLightOnOff" "erebus-kbd-backlight toggle" "Keyboard backlight")
  ];

  # Lua for hyprland.lua; the binds come in order.
  lua = {
    modifier,
    binds,
  }: let
    str = builtins.toJSON;
    keys = b: lib.replaceStrings ["MOD"] [modifier] b.keys;
    action = b:
      if b.shortcut != null
      then "hl.dsp.global(${str "quickshell:${b.shortcut}"})"
      else "hl.dsp.exec_cmd(${str b.command})";
    flags = b:
      lib.filter (f: b.${f.attr}) [
        {
          attr = "release";
          lua = "release";
        }
        {
          attr = "nonConsuming";
          lua = "non_consuming";
        }
        {
          attr = "locked";
          lua = "locked";
        }
        {
          attr = "repeating";
          lua = "repeating";
        }
      ];
    opts = b: let
      f = flags b;
    in
      lib.optionalString (f != []) ", { ${lib.concatMapStringsSep ", " (x: "${x.lua} = true") f} }";
  in ''
    -- erebus-shell keybinds (programs.erebus-shell.keybinds)
    ${lib.concatMapStringsSep "\n" (b: "hl.bind(${str (keys b)}, ${action b}${opts b})") binds}
  '';

  # Every bind that is not plumbing, for a cheat sheet.
  json = {
    modifier,
    binds,
  }:
    builtins.toJSON (map (b: {
      keys = lib.replaceStrings ["MOD"] [modifier] b.keys;
      inherit (b) label;
    }) (lib.filter (b: !b.hidden) binds));
}
