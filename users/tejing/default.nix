{ config, pkgs, ... }:

{
  users.users.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    shell = pkgs.fish;
    hashedPassword = builtins.readFile ./pwhash.secret;
  };

  systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

  home-manager.users.tejing.imports = [
    ../../lib
    ./browser.nix
    ./chat.nix
    ./desktopenvironment.nix
    ./editor.nix
    ./encryption.nix
    ./gaming.nix
    ./media.nix
    ./programming.nix
    ./shell.nix
    ./sound.nix
    ./windowmanager.nix
    ./xterminal.nix
  ];

  # Automatically (re)start/stop and changed services when activating a home-manager configuration.
  home-manager.users.tejing.systemd.user.startServices = true;

  home-manager.users.tejing.home.stateVersion = "20.09";
}
