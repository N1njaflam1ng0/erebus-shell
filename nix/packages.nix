{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    sinks = {
      headphones = "";
      headset = "";
      hdmi = "";
      spdif = "";
    };

    # Defaults for the unconfigured build; hosts use homeModules.default.
    helpers = import ./_helpers {
      inherit pkgs lib sinks;
      gslapper = inputs.gslapper.packages.${system}.gslapper;
      hyprland = pkgs.hyprland;
      lockCommand = "loginctl lock-session";
      wallpaperDir = pkgs.emptyDirectory;
      defaultWallpaper = "";
      screenshotDir = "/tmp";
      clipboardMaxItems = 500;
    };
  in {
    _module.args.erebusHelpers = helpers;

    packages.default = import ./_package {
      inherit pkgs lib helpers sinks;
      hyprland = pkgs.hyprland;
      outputs = {
        primary = "";
        left = "";
        right = "";
      };
      terminal = "ghostty";
    };

    # `qs -p shell` hot-reloads; the checked-in Host.qml resolves helpers from PATH.
    devShells.default = pkgs.mkShell {
      packages = helpers.all ++ (with pkgs; [quickshell cava btop brightnessctl jq]);
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };
  };
}
