{ my, nixosConfig, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      lutris
    ;
    inherit (my.pkgs)
      starsector
    ;
  };

  # prevent compositing performance hit when gaming
  services.picom.extraOptions = "unredir-if-possible = true;";

  xsession.windowManager.i3.config.assigns."8" = [{class = "^Steam$";}];
}
