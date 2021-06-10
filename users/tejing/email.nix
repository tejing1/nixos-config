{ pkgs, ... }:

{
  home.packages = with pkgs; [
    protonmail-bridge
  ];
}
