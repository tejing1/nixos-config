{ pkgs, inputs, ... }:

{
  users.users.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    shell = pkgs.fish;
    hashedPassword = builtins.readFile ./pwhash.secret;
  };
  home-manager.users.tejing.imports = [ inputs.self.homeConfigurations.tejing.configurationModule ];

  programs.fish.enable = true;
  programs.zsh.enable = true;

  # Set available fonts
  fonts.fonts = with pkgs; [ corefonts nerdfonts ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    haskellPackages.git-annex
    lsof # needed for git-annex webapp
    rclone # used to connect git-annex to my phone's ftp server
  ];

  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.mouse.accelSpeed = "0.6";

  programs.dconf.enable = true;

  systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

  # Start urxvtd with user sessions
  services.urxvtd.enable = true;
}
