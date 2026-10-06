# erebus-shell

The Quickshell bar for [erebus](https://github.com/N1njaFlam1ng0/erebus): bar,
launcher (apps, calculator, wallpapers), clipboard history, calendar, media, Wi-Fi,
displays, tray, notifications and OSDs, plus the `erebus-*` helpers it shells
out to. Built for Hyprland with a Lua config.

## Use

```nix
# flake.nix
inputs.erebus-shell = {
  url = "github:N1njaFlam1ng0/erebus-shell";
  inputs.nixpkgs.follows = "nixpkgs";
};

# NixOS
imports = [ inputs.erebus-shell.nixosModules.default ];
programs.erebus-shell.calendar.enable = true;

# home-manager
imports = [ inputs.erebus-shell.homeModules.default ];
programs.erebus-shell = {
  enable = true;
  hyprlandPackage = inputs.hyprland.packages.${system}.hyprland;
  outputs.primary = "DP-1";
  lockCommand = "loginctl lock-session";
  wallpaper.directory = ./wallpapers;
};
```

The module appends the shell's keybinds and its autostart to
`wayland.windowManager.hyprland.extraConfig`; see `keybinds.*` and `autostart`.
It also records clipboard history itself (`erebus-clipboard` user services), so
leave `services.cliphist` off.

After a rebuild, `erebus-restart` swaps the running bar for the new build.

## Develop

```sh
nix develop -c qs -p shell     # hot-reloads; helpers resolve from PATH
nix flake check                # builds the shell, shellchecks helpers, runs the tests
```

To try changes in erebus without pushing:
`nixos-rebuild switch --flake . --override-input erebus-shell path:$HOME/repos/Personal/erebus-shell`
