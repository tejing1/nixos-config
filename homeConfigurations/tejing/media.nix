{ pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      fbreader
      feh
    ;
  };
  programs.mpv.enable = true;
  programs.mpv.config = {
    osc = false;
    hwdec = "auto-safe";
  };
}
