{...}: {
  # System services a home-manager module cannot enable.
  flake.nixosModules.default = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.programs.erebus-shell.calendar.enable = lib.mkEnableOption ''
      Evolution Data Server for the bar's calendar panel. Accounts (Google etc.)
      are added through Evolution: `erebus-calendar auth`
    '';

    config = lib.mkIf config.programs.erebus-shell.calendar.enable {
      # The registry and calendar factory the backend talks to over D-Bus. Both
      # are D-Bus activated, so nothing runs until the shell first asks.
      services.gnome.evolution-data-server.enable = true;
      # Account setup (OAuth) UI, and the full event editor.
      programs.evolution.enable = true;
      environment.systemPackages = [pkgs.gnome-calendar];
    };
  };
}
