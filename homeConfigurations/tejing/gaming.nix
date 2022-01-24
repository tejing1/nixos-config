{ pkgs, ... }:

let
  mySteam = pkgs.steam.override {
    extraPkgs = pkgs: builtins.attrValues {
      inherit (pkgs)

        # stardew valley
        icu

      ;
    };
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
  xsession.windowManager.i3.config.assigns."8" = [{class = "^Steam$";}];
}
