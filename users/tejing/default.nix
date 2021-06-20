{ config, pkgs, ... }:

{
  users.users.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    shell = pkgs.fish;
    hashedPassword = builtins.readFile ./pwhash.secret;
  };

  services.xserver.libinput.mouse.accelSpeed = "0.6";

  systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

  home-manager.users.tejing.imports = [ ../../lib ] ++ (import ../../lib/listimports.nix {}).my.listImports ./.;

  # Automatically (re)start/stop and changed services when activating a home-manager configuration.
  home-manager.users.tejing.systemd.user.startServices = true;

  home-manager.users.tejing.home.stateVersion = "20.09";
}
