# Calendar backend for the bar's calendar panel, on Evolution Data Server.
#
# Why EDS and not the Google Calendar API directly: gcalcli (and anything else
# speaking to Google's API) needs an OAuth client from a Google Cloud project,
# and a personal project stays in "Testing" publishing status unless you own a
# domain, host a home page and privacy policy on it, and verify that domain in
# Search Console. Testing status revokes the refresh token every 7 days. EDS
# ships its own already-verified Google OAuth credentials, so the whole Cloud
# project problem disappears: you add the account once in Evolution and the
# token keeps working.
#
# EDS also gets us recurring events for free -- generate_instances_sync expands
# an RRULE into one entry per occurrence, which the previous gcalcli-backed
# version never did.
{ ... }: {
  flake.nixosModules.calendar = { pkgs, ... }: {
    # The registry and calendar factory the helper talks to over D-Bus. Both are
    # D-Bus activated, so nothing runs until the shell first asks for events.
    services.gnome.evolution-data-server.enable = true;

    # Evolution is how the Google account gets added -- it runs the OAuth flow
    # against EDS's built-in credentials, no Cloud project involved. It doubles
    # as the full event editor the panel's "open" button reaches for.
    programs.evolution.enable = true;

    environment.systemPackages = [ pkgs.gnome-calendar ];
  };

  flake.homeModules.calendar = { pkgs, lib, ... }:
  let
    # EDataServer-1.2.typelib depends on libxml2-2.0, which nixpkgs ships inside
    # gobject-introspection rather than libxml2 -- without it the import fails
    # with "Typelib file for namespace 'libxml2' not found".
    giPackages = [
      pkgs.evolution-data-server
      pkgs.libical
      pkgs.libsoup_3
      pkgs.json-glib
      pkgs.glib
      pkgs.gobject-introspection
    ];

    python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.parsedatetime ]);

    backend = pkgs.runCommand "erebus-calendar-backend"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        src = ./calendar-backend.py;
      }
      ''
        install -Dm755 $src $out/bin/erebus-calendar-backend
        substituteInPlace $out/bin/erebus-calendar-backend \
          --replace '#!/usr/bin/env python3' '#!${python}/bin/python3'
        wrapProgram $out/bin/erebus-calendar-backend \
          --prefix GI_TYPELIB_PATH : "${lib.makeSearchPath "lib/girepository-1.0" giPackages}" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath giPackages}"
      '';

    calendar = pkgs.writeShellScriptBin "erebus-calendar" ''
      set -eu
      backend=${backend}/bin/erebus-calendar-backend
      case "''${1:-}" in
        events)
          [ $# -eq 3 ] || { echo "usage: erebus-calendar events <start> <end>" >&2; exit 2; }
          # An empty array plus a non-zero exit is how services/Calendar.qml
          # tells "no account set up yet" apart from "this month is empty".
          "$backend" events "$2" "$3" || { echo "[]"; exit 1; }
          ;;
        add)
          [ $# -eq 2 ] || { echo "usage: erebus-calendar add <text>" >&2; exit 2; }
          exec "$backend" add "$2" ;;
        calendars)
          exec "$backend" calendars ;;
        auth)
          # Evolution is the account UI: it runs Google's OAuth flow against
          # EDS's built-in credentials. Add the account with
          #   File -> New -> Collection Account
          # then enter the Gmail address, sign in, and untick everything except
          # Calendar unless you want the mail set up too.
          #
          # -c calendar opens on the Calendar view rather than Mail. There is an
          # evolution://new-collection-account URI that the first-run wizard
          # links to, but --view refuses it and exits, so the menu is the way in.
          exec ${pkgs.evolution}/bin/evolution -c calendar ;;
        open)
          exec ${pkgs.gnome-calendar}/bin/gnome-calendar ;;
        *)
          echo "usage: erebus-calendar {events <start> <end>|add <text>|calendars|auth|open}" >&2
          exit 2 ;;
      esac
    '';
  in {
    home.packages = [ calendar ];
  };
}
