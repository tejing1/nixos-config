{ config, pkgs, inputs, ... }:

{
  users.users.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    shell = pkgs.fish;
    hashedPassword = builtins.readFile ./pwhash.secret;
  };
  home-manager.users.tejing.imports = [ inputs.self.homeConfigurations.tejing.configurationModule ];

  programs.zsh.enable = true;

  services.xserver.libinput.mouse.accelSpeed = "0.6";

  programs.dconf.enable = true;

  systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];
}
