{
  description = "erebus-shell: the Quickshell bar and its helpers, for Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    # Wallpaper engine: plays both stills and video, driven by erebus-wallpaper.
    gslapper = {
      url = "github:Nomadcxx/gSlapper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./nix);
}
