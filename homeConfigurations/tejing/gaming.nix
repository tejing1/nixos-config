{ pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      steam
      lutris
    ;
  };
  xsession.windowManager.i3.config.assigns."8" = [{class = "^Steam$";}];
}
