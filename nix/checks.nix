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

    # A helper built against the fakes in _helpers/stubs instead of the real CLIs.
    stub = name: pkgs.writeShellScriptBin name (builtins.readFile ./_helpers/stubs/${name}.sh);
    stubbed = import ./_helpers/script.nix {inherit pkgs;};
    calendarStubbed = stubbed "calendar" (map stub ["erebus-calendar-backend" "evolution" "gnome-calendar"]) {};

    # Runs tests/<name>/shell.qml headless against a copy of shell/; it prints PASS.
    qmlTest = name: {
      inputs ? [],
      setup ? "",
    }:
      pkgs.runCommand "erebus-${name}-qml-test" {nativeBuildInputs = [pkgs.quickshell] ++ inputs;} ''
        export HOME=$PWD/home XDG_CACHE_HOME=$PWD/cache XDG_STATE_HOME=$PWD/state
        export XDG_RUNTIME_DIR=$PWD QT_QPA_PLATFORM=offscreen
        mkdir -p $HOME $XDG_STATE_HOME/erebus
        cp -r ${../shell} cfg && chmod -R u+w cfg
        cp ${../tests/${name}/shell.qml} cfg/shell.qml
        ${setup}
        timeout 60 quickshell -p cfg 2>&1 | tee log
        grep -q PASS log
        touch $out
      '';
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

      calendar = pkgs.runCommand "erebus-calendar-test" {nativeBuildInputs = [calendarStubbed pkgs.jq];} ''
        bash ${./_helpers/calendar-test.sh}
        touch $out
      '';

      # Builds the CalDAV source for real, against Evolution Data Server's
      # typelibs; committing it needs a running server, so that is not covered.
      calendar-backend = pkgs.runCommand "erebus-calendar-backend-test" {
        nativeBuildInputs = [ erebusHelpers.calendarBackend pkgs.jq ];
      } ''
        cfg=$(erebus-calendar-backend caldav-config Work https://cloud.example.org:8443/remote.php/dav/calendars/me/personal/ me)
        for want in 'DisplayName=Work' 'BackendName=caldav' 'Host=cloud.example.org' 'Port=8443' 'User=me' \
                    'Method=tls' 'ResourcePath=/remote.php/dav/calendars/me/personal/'; do
          grep -qxF "$want" <<< "$cfg" || { echo "FAIL: missing $want in:"; echo "$cfg"; exit 1; }
        done
        plain=$(erebus-calendar-backend caldav-config Home http://nas.lan/dav/ me)
        grep -qxF 'Port=80' <<< "$plain" || { echo "FAIL: default http port"; exit 1; }
        grep -qxF 'Method=none' <<< "$plain" || { echo "FAIL: plain http is not secured"; exit 1; }
        if erebus-calendar-backend caldav-config Bad ftp://nas/dav me 2>/dev/null; then echo "FAIL: ftp accepted"; exit 1; fi
        if erebus-calendar-backend caldav-config Bad nas/dav me 2>/dev/null; then echo "FAIL: schemeless address accepted"; exit 1; fi
        # Evolution's Google sign-in has saved another address in the path: 404.
        [ "$(erebus-calendar-backend google-path me@gmail.com /caldav/v2/chris@gmail.com/events)" = /caldav/v2/me@gmail.com/events ] || { echo "FAIL: google path not corrected"; exit 1; }
        [ -z "$(erebus-calendar-backend google-path me@gmail.com /caldav/v2/me@gmail.com/events)" ] || { echo "FAIL: correct google path changed"; exit 1; }
        [ -z "$(erebus-calendar-backend google-path me /remote.php/dav/calendars/me/personal/)" ] || { echo "FAIL: non-google path changed"; exit 1; }
        # Google's calendar listing: calendars are picked out, other collections skipped, paths unescaped.
        found=$(erebus-calendar-backend parse-google <<'XML'
        <D:multistatus xmlns:D="DAV:" xmlns:caldav="urn:ietf:params:xml:ns:caldav">
          <D:response><D:href>/caldav/v2/me%40gmail.com/events/</D:href><D:propstat><D:prop>
            <D:displayname>me@gmail.com</D:displayname><D:resourcetype><D:collection/><caldav:calendar/></D:resourcetype></D:prop></D:propstat></D:response>
          <D:response><D:href>/caldav/v2/abc%40group.calendar.google.com/events/</D:href><D:propstat><D:prop>
            <D:displayname>Family</D:displayname><D:resourcetype><D:collection/><caldav:calendar/></D:resourcetype></D:prop></D:propstat></D:response>
          <D:response><D:href>/caldav/v2/me%40gmail.com/inbox/</D:href><D:propstat><D:prop>
            <D:resourcetype><D:collection/><caldav:schedule-inbox/></D:resourcetype></D:prop></D:propstat></D:response>
        </D:multistatus>
        XML
        )
        [ "$(jq -c 'map(.path)' <<< "$found")" = '["/caldav/v2/me@gmail.com/events","/caldav/v2/abc@group.calendar.google.com/events"]' ] || { echo "FAIL: google calendars: $found"; exit 1; }
        [ "$(jq -r '.[1].name' <<< "$found")" = Family ] || { echo "FAIL: google calendar name"; exit 1; }
        touch $out
      '';


      # Against a real cliphist database.
      clipboard = pkgs.runCommand "erebus-clipboard-test" {
        nativeBuildInputs = [erebusHelpers.clipboard pkgs.imagemagick pkgs.jq];
      } ''
        bash ${./_helpers/clipboard-test.sh}
        touch $out
      '';

      calendar-panel = qmlTest "calendar" {
        setup = ''
          export STUB_DIR=$PWD/stub
          mkdir -p $STUB_DIR
          touch $STUB_DIR/no-calendar
          printf '[{"name":"me@gmail.com","path":"/caldav/v2/me@gmail.com/events","added":true,"primary":true},{"name":"Family","path":"/caldav/v2/x@group.calendar.google.com/events","added":false,"primary":false}]' > $STUB_DIR/google.json
          substituteInPlace cfg/config/Host.qml --replace-fail '"erebus-calendar"' '"${lib.getExe calendarStubbed}"'
        '';
      };

      clipboard-panel = qmlTest "clipboard" {
        inputs = [erebusHelpers.clipboard pkgs.imagemagick];
        setup = ''
          substituteInPlace cfg/config/Host.qml --replace-fail '"erebus-clipboard"' '"${lib.getExe erebusHelpers.clipboard}"'
          printf 'Some notes\nsecond line\nthird' | erebus-clipboard store
          printf '#b8bb26' | erebus-clipboard store
          printf 'https://example.com' | erebus-clipboard store
          magick -size 1362x766 gradient:red-blue image.png
          erebus-clipboard store < image.png
        '';
      };

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
