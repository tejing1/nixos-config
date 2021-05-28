# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./users
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
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true; # hopefully temporary, for bootstrapping out of BIOS mode
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.timeout = 1;
  # graphical boot progress display
#  boot.plymouth.enable = true;
  # quiet boot
  boot.kernelParams = [ "quiet" ];

  virtualisation.virtualbox.host.enable = true;

  networking.hostName = "tejingdesk"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "US/Eastern";

  # Don't bother with the lecture or the need to keep state about who's been lectured
  security.sudo.extraConfig = "Defaults lecture=\"never\"";

  # Enable NTP synchronization
  #services.ntp.enable = true; # superceded by systemd-timesyncd

  # Allow automatic upgrades, but never auto-reboot
  #system.autoUpgrade.enable = true;
  #system.autoUpgrade.allowReboot = false;

  # Enable Microsoft CoreFonts
  #fonts.enableCoreFonts = true; # OLD format
  fonts.fonts = with pkgs; [ corefonts nerdfonts ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Needed to work with my flake
    git git-crypt

    nix-index

    mpd
    haskellPackages.git-annex
    lsof # needed for git-annex webapp
    rclone # used to connect git-annex to my phone's ftp server
    wireshark
  ];

  # Enable fish
  programs.fish.enable = true;

  # List services that you want to enable:

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
  services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.layout = "us";
  services.xserver.xkbOptions = "caps:none";

  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  #services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.desktopManager.plasma5.enable = true;

  # Enable i3.
  #services.xserver.windowManager.i3.enable = true;
  #services.xserver.windowManager.i3.package = pkgs.i3-gaps;

  # Have SDDM enable numlock on boot
  #services.xserver.displayManager.sddm.autoNumlock = true;

  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [
    # Proprietary NVIDIA driver
    "nvidia"
    # default list as a fallback (and for when I used "nixos-rebuild build-vm")
    "radeon"
    "cirrus"
    "vesa"
    "modesetting"
    ];
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiVdpau libvdpau-va-gl ];

  # Enable pulseaudio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  nixpkgs.config.pulseaudio = true;

  # Start urxvtd with user sessions
  services.urxvtd.enable = true;

  # Start mpd service
  services.mpd.enable = true;
  services.mpd.musicDirectory = "/mnt/share/replaceable/music_database";
  services.mpd.startWhenNeeded = true;

  # Let the system-wide mpd service play to the per-user pulseaudio daemon via tcp
  hardware.pulseaudio.tcp.enable = true;
  hardware.pulseaudio.tcp.anonymousClients.allowedIpRanges = [ "127.0.0.1" ];
  services.mpd.extraConfig = ''
		audio_output {
		       type     "pulse"
		       name     "pulseaudio tcp on 127.0.0.1"
		       server   "127.0.0.1"
		}'';

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "17.09"; # Did you read the comment?

}
