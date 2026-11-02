{ inputs, my, ... }:

let
  inherit (my.lib) listImportablePathsExcept;

  modules = (listImportablePathsExcept ./. [ "fpentry" ]);

in

{
  users.tejing.hm.cfg = { lib, ... }: {
    imports = modules;

    home.username = lib.mkDefault "tejing";
    home.homeDirectory = lib.mkDefault "/home/tejing";
  };
}
