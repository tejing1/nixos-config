{ config, my, pkgs, ... }:

{
  home.packages = with pkgs; [
    my.pkgs.myterm
    my.pkgs.mylaunchterm
    my.pkgs.mylaunch
  ];
  programs.urxvt.enable = true;
  programs.urxvt.fonts = [ "xft:DejaVuSansMono Nerd Font Mono:pixelsize=15" ];
  programs.urxvt.scroll.bar.enable = false;
  programs.urxvt.scroll.lines = 0;
  programs.urxvt.iso14755 = false;
  programs.urxvt.extraConfig = {
    background = "rgba:0000/0000/0000/C000";
    foreground = "#00ff00";
    depth = 32;
    internalBorder = 0;
    perl-ext-common = "default,-readline,-searchable-scrollback";
  };
  xsession.windowManager.i3.config.keybindings = let
    mod = config.xsession.windowManager.i3.config.modifier;
  in {
    "${mod}+Return" = "exec --no-startup-id ${my.scripts.myterm}";
  };
  xresources.properties = {
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
  };
}
