{ nixosConfig, pkgs, ... }:

let
  mySteam = pkgs.steam.override {
    extraPkgs = pkgs: builtins.attrValues {
      inherit (pkgs)

        # stardew valley
        icu

      ;
    };

    # copied from nixos steam module
    extraLibraries = pkgs:
      let inherit (nixosConfig.hardware.opengl) package package32 extraPackages extraPackages32; in
      if pkgs.hostPlatform.is64bit then [ package ] ++ extraPackages else [ package32 ] ++ extraPackages32;
  };
in
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      lutris
    ;
    inherit mySteam;
    steam-run = mySteam.run;
  };

  # prevent compositing performance hit when gaming
  services.picom.extraOptions = "unredir-if-possible = true;";

  xsession.windowManager.i3.config.assigns."8" = [{class = "^Steam$";}];
}
