{...}: {
  perSystem = {
    pkgs,
    lib,
    config,
    erebusHelpers,
    ...
  }: let
    kb = import ./_keybinds {inherit lib;};
    binds = map (b:
      {
        shortcut = null;
        command = null;
        release = false;
        nonConsuming = false;
        locked = false;
        repeating = false;
        hidden = false;
      }
      // b)
    kb.defaults;
    lua = pkgs.writeText "keybinds.lua" (kb.lua {
      modifier = "SUPER";
      inherit binds;
    });
  in {
    checks = {
      # Builds Host.qml, the QML import guard, and every helper (shellcheck).
      shell = config.packages.default;

      helpers = pkgs.runCommand "erebus-helpers-test" {nativeBuildInputs = erebusHelpers.all;} ''
        # Every helper rejects an unknown verb with its usage line and exit 2.
        for h in power audio-switch brightness calc clipboard calendar monitors wallpaper; do
          set +e
          HOME=$PWD XDG_STATE_HOME=$PWD/state XDG_RUNTIME_DIR=$PWD erebus-$h no-such-verb 2> err
          rc=$?
          set -e
          [ $rc -eq 2 ] || { echo "FAIL: erebus-$h exited $rc"; cat err; exit 1; }
          grep -q "usage: erebus-$h" err || { echo "FAIL: erebus-$h usage"; cat err; exit 1; }
        done
        touch $out
      '';

      keybinds = pkgs.runCommand "erebus-keybinds-test" {nativeBuildInputs = [pkgs.lua];} ''
        luac -p ${lua}
        [ "$(grep -c '^hl.bind(' ${lua})" = ${toString (builtins.length binds)} ] || { echo "FAIL: one hl.bind per entry"; exit 1; }
        grep -qF 'hl.bind("SUPER + U", hl.dsp.global("quickshell:togglePower"))' ${lua} || { echo "FAIL: shortcut bind"; exit 1; }
        grep -qF 'hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("erebus-brightness up"), { repeating = true })' ${lua} || { echo "FAIL: command bind"; exit 1; }
        touch $out
      '';
    };
  };
}
