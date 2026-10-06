{inputs, ...}: {
  flake.homeModules.default = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.programs.erebus-shell;
    inherit (lib) mkOption types;
    system = pkgs.stdenv.hostPlatform.system;
    keybinds = import ./_keybinds {inherit lib;};
    gslapper = inputs.gslapper.packages.${system}.gslapper;

    helpers = import ./_helpers {
      inherit pkgs lib gslapper;
      inherit (cfg) lockCommand sinks;
      hyprland = cfg.hyprlandPackage;
      wallpaperDir = cfg.wallpaper.directory;
      defaultWallpaper = cfg.wallpaper.default;
      screenshotDir = cfg.screenshotDirectory;
    };

    shell = import ./_package {
      inherit pkgs lib helpers;
      inherit (cfg) outputs terminal sinks;
      hyprland = cfg.hyprlandPackage;
    };

    role = description:
      mkOption {
        type = types.str;
        default = "";
        inherit description;
      };

    sink = description:
      mkOption {
        type = types.str;
        default = "";
        description = "PipeWire node name of the ${description} sink, or \"\" for none.";
      };
  in {
    options.programs.erebus-shell = {
      enable = lib.mkEnableOption "the erebus Quickshell bar";

      package = mkOption {
        type = types.package;
        readOnly = true;
        default = shell;
        description = "The configured `erebus-shell` launcher.";
      };

      hyprlandPackage = mkOption {
        type = types.package;
        default = pkgs.hyprland;
        description = "Hyprland providing hyprctl; should match the running compositor.";
      };

      outputs = {
        primary = role "Output that gets the primary bar layout and the notification toasts.";
        left = role "Output in the 'left' role, or \"\" if this host has none.";
        right = role "Output in the 'right' role, or \"\" if this host has none.";
      };

      terminal = mkOption {
        type = types.str;
        default = "ghostty";
        description = "Terminal the launcher uses for run-in-terminal entries.";
      };

      lockCommand = mkOption {
        type = types.str;
        default = "loginctl lock-session";
        description = "Command run by `erebus-power lock` (the power menu's Lock entry).";
      };

      screenshotDirectory = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Pictures/screenshots";
        description = "Where screenshots are saved.";
      };

      wallpaper = {
        directory = mkOption {
          type = types.path;
          description = ''
            Root of the wallpaper picker; stills and videos. Must be buildable
            into the store (a path literal or a flake path): picker thumbnails
            are generated from it at build time.
          '';
        };
        default = mkOption {
          type = types.str;
          default = "";
          description = "Wallpaper, relative to `directory`, for outputs without a saved choice.";
        };
      };

      sinks = {
        headphones = sink "headphones";
        headset = sink "headset";
        hdmi = sink "HDMI";
        spdif = sink "S/PDIF";
      };

      autostart = mkOption {
        type = types.bool;
        default = true;
        description = "Start the shell and restore wallpapers when Hyprland starts.";
      };

      keybinds = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Bind the shell's shortcuts in Hyprland.";
        };
        modifier = mkOption {
          type = types.str;
          default = "SUPER";
          description = "What MOD stands for in `keybinds.binds`.";
        };
        binds = mkOption {
          default = keybinds.defaults;
          description = ''
            Binds in order. Each sets `shortcut` (a quickshell global shortcut
            name) or `command` (run with `exec_cmd`), the `keys` as Hyprland
            writes them with MOD for the modifier, and a `label`.
          '';
          type = types.listOf (types.submodule {
            options = {
              keys = mkOption {type = types.str;};
              label = mkOption {type = types.str;};
              shortcut = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              command = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              release = mkOption {
                type = types.bool;
                default = false;
              };
              nonConsuming = mkOption {
                type = types.bool;
                default = false;
              };
              locked = mkOption {
                type = types.bool;
                default = false;
              };
              repeating = mkOption {
                type = types.bool;
                default = false;
              };
              hidden = mkOption {
                type = types.bool;
                default = false;
                description = "Bound, but left out of the cheat sheet.";
              };
            };
          });
        };
      };
    };

    config = lib.mkIf cfg.enable {
      home.packages = [shell pkgs.quickshell pkgs.cava gslapper] ++ helpers.all;

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter (lib.concatStringsSep "\n" (
        lib.optional cfg.autostart ''
          hl.on("hyprland.start", function()
            hl.exec_cmd("erebus-shell -d")
            -- Reapply saved per-output wallpapers; paths are stored relative to
            -- the wallpaper root so they survive a rebuild or a GC.
            hl.exec_cmd("erebus-wallpaper restore")
          end)
        ''
        ++ lib.optional cfg.keybinds.enable
        (keybinds.lua {inherit (cfg.keybinds) modifier binds;})
      ));

      xdg.configFile."erebus-shell/keybinds.json" = lib.mkIf cfg.keybinds.enable {
        text = keybinds.json {inherit (cfg.keybinds) modifier binds;};
      };

      # Feeds the media panel's visualiser. `raw` output on stdout is what
      # services/AudioData.qml parses.
      xdg.configFile."cava/erebus.ini".text = ''
        ; ascii/raw on stdout is what services/AudioData.qml reads, and
        ; ascii_max_range must stay 100 because that parser divides each value
        ; by 100. One column per bar in modules/media/MediaPanel.qml's progress
        ; bar; mono, since stereo draws a mirrored spectrum.
        [general]
        bars = 48

        [output]
        method = raw
        channels = mono
        data_format = ascii
        ascii_max_range = 100
      '';
    };
  };
}
