{...}: {
  # System services a home-manager module cannot enable.
  flake.nixosModules.default = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.programs.erebus-shell.calendar.enable = lib.mkEnableOption ''
      Evolution Data Server for the bar's calendar panel. Accounts are added
      from the panel: Google through Evolution's sign-in, CalDAV by address
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
