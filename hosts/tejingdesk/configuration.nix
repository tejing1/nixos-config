# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../users
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
  boot.loader.grub.gfxmodeEfi = "3840x2160x24,auto";

  # Define your hostname.
  networking.hostName = "tejingdesk";

  # Set your time zone.
  time.timeZone = "US/Eastern";

  # Don't bother with the lecture or the need to keep state about who's been lectured
  security.sudo.extraConfig = "Defaults lecture=\"never\"";

  # Set available fonts
  fonts.fonts = with pkgs; [ corefonts nerdfonts ];

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

  # Enable virtualbox host stuff
  virtualisation.virtualbox.host.enable = true;

  # Enable the OpenSSH daemon.
#  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Publish hostname via mdns and resolve *.local dns names via mdns
#  services.avahi.enable = true;
#  services.avahi.nssmdns = true;
#  services.avahi.publish.enable = true;
#  services.avahi.publish.addresses = true;
  #services.avahi.publish.workstation = true;

  # hardcoded hosts entry for my Samsung A51 smartphone
#  networking.hosts = { "192.168.0.104" = [ "phone.local" ];};

  # Enable CUPS to print documents.
#  services.printing.enable = true;

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
