{ pkgs, ... }:

{
  home.packages = with pkgs; [
    steam
    lutris
  ];
  xsession.windowManager.i3.config.assigns."8" = [{class = "^Steam$";}];
}
