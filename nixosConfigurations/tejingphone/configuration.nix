{ config, inputs, lib, my, pkgs, ... }:
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

  networking.hostName = "tejingphone";

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
      git
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

  nixpkgs.overlays = [
    my.overlays.editline-urxvt-home-end-fix
  ];

  nix = {
    # Use the new CLI and enable flakes
    settings.experimental-features = "nix-command flakes";
    # Make builds run with low priority so my system stays responsive
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    # Hard link identical files in the store automatically
    settings.auto-optimise-store = true;
    # automatically trigger garbage collection
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

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

  programs.zsh.enable = true;

  users.users."tejing" = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
    password = mkIf (config.users.users.tejing.hashedPassword == null) "password"; # Fallback for locked build
    hashedPassword = readSecret null ../../homeConfigurations/tejing/pwhash.secret;
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDD59yTSccmS5YdrrbH79dtnyqqQ6Jid+i2D2DIaO5I/4UnI4s2eff7MAXF5xg80eEilzpbqR+BMykbEtCRkosNk0WYfbrbTmosihmItPe+xkoedQpKd60ADyYMjmJSfUrHbIZ4E07BacZcD+UUM5s4cYZPjxDjz9DFgychhG4BN0m8vjQOP1ds9jvPqnZw2tmcGCuim8c1lQDMAiYZXV+Vqrda31iFFb87fmsHv7ZlVXaUPJ2RJjz6a+LsD49eV2pSycatwM7Z4bM+DD7HJR+HvDQxfLwWP2bVxxBw3KSXNHGTlnH9VF/n11vWnkiNcPV4QbHpKd2Y5MKxU3eGLJ/ subkey 004FFE9C78916342 of key 46E96F6FF44F3D74 keygrip is 0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
    extraGroups = [
      "dialout"
      "feedbackd"
      "networkmanager"
      "video"
      #"audio"
      "wheel"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
