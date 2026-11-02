{ config, my, pkgs, ... }:

{
  programs.zsh.dirHashes = {
    nixpkgs = "/etc/nix/path/nixpkgs";
    home-manager = "/etc/nix/path/home-manager";
    share = "/mnt/persist/share";
    flake = "/mnt/persist/tejing/flake";
  };
  programs.fish.loginShellInit = ''
    cd ~/data
  '';
  programs.zsh.loginExtra = ''
    cd ~/data
  '';
}
