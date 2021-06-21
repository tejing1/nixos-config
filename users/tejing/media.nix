{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fbreader
    feh
  ];
  programs.mpv.enable = true;
  programs.mpv.config = {
    osc = false;
    hwdec = "auto-safe";
  };
}
