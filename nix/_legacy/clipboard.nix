# Clipboard history front-end. The cliphist daemon already runs (see
# desktop/clipboard.nix: services.cliphist, 500 items, images on); Noctalia only
# ever supplied the picker UI, so this replaces that half.
{ ... }: {
  flake.homeModules.clipboard-tools = { pkgs, ... }:
  let
    # cliphist stores entries as "<id>\t<preview>". The id is what decode wants.
    clip = pkgs.writeShellScriptBin "erebus-clipboard" ''
      set -eu
      cliphist=${pkgs.cliphist}/bin/cliphist
      case "''${1:-list}" in
        list)
          # Tab-separated id/preview, straight through to the picker.
          exec $cliphist list ;;
        copy)
          # Takes an id on argv so the caller never has to re-quote the preview.
          [ $# -ge 2 ] || { echo "usage: erebus-clipboard copy <id>" >&2; exit 2; }
          printf '%s\t' "$2" | $cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy ;;
        delete)
          [ $# -ge 2 ] || { echo "usage: erebus-clipboard delete <id>" >&2; exit 2; }
          printf '%s\t' "$2" | $cliphist delete ;;
        wipe)
          exec $cliphist wipe ;;
        *)
          echo "usage: erebus-clipboard {list|copy <id>|delete <id>|wipe}" >&2
          exit 2 ;;
      esac
    '';
  in {
    home.packages = [ clip ];
  };
}
