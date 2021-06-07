{ pkgs, my, ... }:

{
  home.packages = with pkgs; [
    my.pkgs.mybrowser
  ];
  xsession.windowManager.i3.config.assigns."12" = [{ class = "^Brave-browser$"; instance = "^brave-browser$"; }];
  xsession.windowManager.i3.config.startup = [{ command = "${my.scripts.mybrowser}"; always = false; notification = false; }];
}
