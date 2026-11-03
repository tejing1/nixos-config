{ lib, my, ... }:

let
  legacyModules = [
    ./bittorrent
    ./browser
    ./chat.nix
    ./editor.nix
    ./email
    ./encryption.nix
    ./gaming.nix
    ./home-manager.nix
    ./keyboard.nix
    ./launching.nix
    ./media
    ./news
    ./notifications.nix
    ./sound.nix
    ./windowmanager.nix
    ./xterminal.nix
  ];
in

{
  my.flake.modules = lib.subtractLists legacyModules (my.lib.listFlakePartsModules ./.);

  users.tejing.hm.cfg = { lib, ... }: {
    imports = legacyModules;

    home.username = lib.mkDefault "tejing";
    home.homeDirectory = lib.mkDefault "/home/tejing";
  };
}
