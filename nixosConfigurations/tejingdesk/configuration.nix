# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nixpkgs.overlays = [
    # make `nix repl` handle home and end keys in urxvt properly
    (final: prev: {editline = prev.editline.overrideAttrs (old:{patches = old.patches ++ [ ./urxvt_fix.patch ];});})

    # prevent nixos-option from pointlessly pulling in stable nix
    (final: prev: {nix = config.nix.package;})
  ];

  nix = {
    # Use a version of nix with flake support
    package = pkgs.nixFlakes;
    # Use the new CLI and enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Hard link identical files in the store automatically
    autoOptimiseStore = true;
    # automatically trigger garbage collection
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 30d";
  };

  # Configure boot loader
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.timeout = 1;
  boot.kernelParams = [ "quiet" ];
  boot.loader.grub.gfxmodeEfi = "3840x2160,1280x1024,auto";

  # Set your time zone.
  time.timeZone = "US/Eastern";

  # Set available fonts
  fonts.fonts = with pkgs; [ corefonts nerdfonts ];

  # cancel the default alias 'l'
  environment.shellAliases.l = null;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Needed to work with my flake
    git git-crypt

    haskellPackages.git-annex
    lsof # needed for git-annex webapp
    rclone # used to connect git-annex to my phone's ftp server
  ];

  # Enable fish
  programs.fish.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;
  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/mnt/persist/tejingdesk/ssh_host_keys/ssh_host_rsa_key"; }
    { type = "ed25519";          path = "/mnt/persist/tejingdesk/ssh_host_keys/ssh_host_ed25519_key"; }
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Disable Caps Lock in X
  services.xserver.xkbOptions = "caps:none";

  # Set console keymap based on X keymap
  console.useXkbConfig = true;

  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;

  # Enable LightDM
  services.xserver.displayManager.lightdm.enable = true;

  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  # Hardware-accelerated video decoding
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
  # 32-bit graphics libraries
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiVdpau libvdpau-va-gl ];

  # Enable pulseaudio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  nixpkgs.config.pulseaudio = true;

  # Start urxvtd with user sessions
  services.urxvtd.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "17.09"; # Did you read the comment?

}
