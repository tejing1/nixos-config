{
  inputs,
  my,
  ...
}:

{
  my.flake.modules = my.lib.listFlakePartsModules ./.;

  hosts.tejingdesk = {
    enable = true;
    type = "nixos";

    #nixpkgs.system = "x86_64-linux";
    #nixpkgs.name = "stable";

    nixpkgs.src = inputs.nixpkgs;
    nixpkgs.instantiation = "internal";
    nixos.cfg.nixpkgs.hostPlatform = "x86_64-linux";

    hm.src = inputs.home-manager;
    hm.module = true;

    users.tejing.enable = true;
    users.tejing.type = "hm-module";
  };

  # FIXME move all this to the proper locations after they are converted to flake-parts modules
  my.nixpkgs.allowUnfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
    "steam"
    "steam-unwrapped"
    "starsector"
  ];
  my.nixpkgs.overlays = [
    my.overlays.gh-urxvt-fix-termenv
  ];
}
