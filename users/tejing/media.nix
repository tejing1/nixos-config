{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mpv
    fbreader
  ];
}
