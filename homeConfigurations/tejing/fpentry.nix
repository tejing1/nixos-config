{ my, ... }:

{
  my.flake.modules = my.lib.listFlakePartsModules ./.;

  users.tejing.hm.cfg = { lib, ... }: {
    home.username = lib.mkDefault "tejing";
    home.homeDirectory = lib.mkDefault "/home/tejing";
  };
}
