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

  # FIXME move this to the proper location after it is converted to a flake-parts module
  my.nixpkgs.overlays = [
    my.overlays.gh-urxvt-fix-termenv
  ];
}
