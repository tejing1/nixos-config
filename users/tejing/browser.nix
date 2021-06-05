{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brave
  ];
  xsession.windowManager.i3.config.assigns."12" = [{ class = "^Brave-browser$"; instance = "^brave-browser$"; }];
  xsession.windowManager.i3.config.startup = [{ command = "${pkgs.brave}/bin/brave"; always = false; notification = false; }];
}