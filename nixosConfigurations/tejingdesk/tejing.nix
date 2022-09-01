{ config, inputs, lib, my, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (my.lib) readSecret;
in

{
  users.users.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" "deluge" ];
    shell = pkgs.zsh;
    password = mkIf (config.users.users.tejing.hashedPassword == null) "password"; # Fallback for locked build
    hashedPassword = readSecret null ../../homeConfigurations/tejing/pwhash.secret;
  };
  home-manager.users.tejing.imports = [ inputs.self.homeConfigurations.tejing.configurationModule ];

  # unlock gpg keys with my login password
  security.pam.services.login.gnupg.enable = true;
  security.pam.services.login.gnupg.noAutostart = true;
  security.pam.services.login.gnupg.storeOnly = true;
  security.pam.services.i3lock.gnupg.enable = true;

  programs.fish.enable = true;
  programs.zsh.enable = true;

  # Set available fonts
  fonts.fonts = builtins.attrValues {
    inherit (pkgs)
      corefonts
      nerdfonts
    ;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs.haskellPackages)
      git-annex
    ;
    inherit (pkgs)
      lsof # needed for git-annex webapp
      rclone # used to connect git-annex to my phone's ftp server
    ;
  };

  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.mouse.accelSpeed = "0.6";

  programs.dconf.enable = true;

  systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

  # Start urxvtd with user sessions
  services.urxvtd.enable = true;

  # rtorrent peer & dht ports
  networking.firewall.allowedTCPPorts = [ 62813 ];
  networking.firewall.allowedUDPPorts = [ 62813 ];
}
