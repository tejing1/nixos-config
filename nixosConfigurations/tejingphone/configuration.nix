{ config, home-manager, inputs, lib, my, nixpkgs, pkgs, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib) mkIf mkForce;
  inherit (my.lib) readSecret;
in

{
  imports = [
    (import "${inputs.mobile-nixos}/lib/configuration.nix" { device = "pine64-pinephonepro"; })
    ./hardware-configuration.nix
    "${inputs.mobile-nixos}/examples/phosh/phosh.nix"
    #<sxmo-nix/modules/sxmo>
    #<sxmo-nix/modules/tinydm>
    home-manager.nixosModules.home-manager
  ];

  # SXMO-related
  #services.xserver = {
  #  enable = true;
  #  desktopManager.sxmo.enable = true;

  #  displayManager = {
  #    tinydm.enable = true;    # power->toggle WM in sxmo only works with tinytm
  #    autoLogin.enable = true;
  #    autoLogin.user = "tejing";
  #    defaultSession = "swmo"; # Or sxmo for X session
  #  };
  #};

  # Prevents graphical glitches
  mobile.quirks.supportsStage-0 = mkForce false;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  environment.systemPackages = attrValues {
    inherit (pkgs)
      emacs
      rxvt-unicode # For terminfo
      foot
      mpv
      htop
      pulsemixer
      pavucontrol
    ;
  } ++ [
    (pkgs.writeShellScriptBin "my-rewrite-boot-partition" ''
      echocmd() {
        echo "$@"
        "$@"
      }
      echocmd sudo dd if=${config.mobile.outputs.u-boot.boot-partition}/mobile-nixos-boot.img of=/dev/mmcblk2p1 bs=8M oflag=direct,sync status=progress
    '')
  ];

  time.timeZone = "US/Eastern";

  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;

  # Make the nix daemon only use the performance cores
  # 0-3 are efficiency cores, 4-5 are performance cores
  systemd.services.nix-daemon.serviceConfig.CPUAffinity = "4,5";
  nix.settings.cores = 2;

  # Keep memory use low. Build one thing at a time...
  nix.settings.max-jobs = 1;

  my.customize.nix = true;
  my.customize.registry = true;
  my.customize.shell = true;
  my.command-not-found.stateDir = "/my/command-not-found";
  systemd.tmpfiles.rules = [ "d /my/command-not-found 0755 root root - -" ];

  environment.etc."nixos/flake.nix".source = "/home/tejing/nixos-config/flake.nix";

  #
  # Opinionated defaults
  #

  # Use Network Manager
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  # Use PulseAudio
  hardware.pulseaudio.enable = true;

  # Enable Bluetooth
  hardware.bluetooth.enable = true;

  # Bluetooth audio
  hardware.pulseaudio.package = pkgs.pulseaudioFull;

  # Enable power management options
  powerManagement.enable = true;

  # Auto-login for phosh
  services.xserver.desktopManager.phosh = {
    user = "tejing";
  };

  #
  # User configuration
  #

  my.customize.users = true;
  my.users.tejing.enable = true;
  users.users.tejing.extraGroups = [
    "dialout"
    "feedbackd"
    "networkmanager"
    "video"
  ];
  home-manager.users.tejing.imports = [
    inputs.self.homeModules.tejing
  ];
  home-manager.users.tejing.my.customize.shell = true;
  home-manager.users.tejing.home.stateVersion = "22.11";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
