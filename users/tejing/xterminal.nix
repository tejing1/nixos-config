{ config, pkgs, mylib, ... }:

{
  home.packages = with pkgs; [
    rxvt_unicode
    (mylib.templateScriptBin pkgs "myterm" scripts/myterm)
  ];
  programs.urxvt.enable = true;
  programs.urxvt.fonts = [ "xft:DejaVuSansMono Nerd Font Mono:pixelsize=15" ];
  programs.urxvt.scroll.bar.enable = false;
  programs.urxvt.scroll.lines = 0;
  programs.urxvt.extraConfig = {
    background = "rgba:0000/0000/0000/C000";
    foreground = "#00ff00";
    depth = 32;
    internalBorder = 0;
  };
  xsession.windowManager.i3.config.keybindings = let
    mod = config.xsession.windowManager.i3.config.modifier;
  in {
    "${mod}+Return" = "exec --no-startup-id ${mylib.templateScriptBin pkgs "myterm" scripts/myterm}/bin/myterm";
  };
  xresources.properties = {
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
  };
}
