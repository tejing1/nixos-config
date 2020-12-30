{ config, pkgs, ... }:

{
  users.users.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    shell = pkgs.fish;
    hashedPassword = builtins.readFile ./pwhash.secret;
  };
  home-manager.users.tejing = { imports = [ ./home.nix ];};
}
