{ config, inputs, lib, my, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  inherit (my.lib) readSecret;
in
{
  options.my.users.tejing.enable = mkEnableOption "user \"tejing\"";
  options.my.users.tejing.pam = mkEnableOption "pam settings for user \"tejing\"";
  options.my.users.tejing.desktop = mkEnableOption "desktop-specific settings for user \"tejing\"";
  options.my.users.tejing.network = mkEnableOption "networking settings for user \"tejing\"";
  options.my.users.tejing.adb = mkEnableOption "adb usage by user \"tejing\"";
  config = mkIf my.users.tejing.enable (mkMerge [
    {
      users.users.tejing = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" "audio" ];
        shell = pkgs.zsh;
        password = mkIf (config.users.users.tejing.hashedPassword == null) "password"; # Fallback for locked build
        hashedPassword = readSecret null ./pwhash.secret;
        openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDD59yTSccmS5YdrrbH79dtnyqqQ6Jid+i2D2DIaO5I/4UnI4s2eff7MAXF5xg80eEilzpbqR+BMykbEtCRkosNk0WYfbrbTmosihmItPe+xkoedQpKd60ADyYMjmJSfUrHbIZ4E07BacZcD+UUM5s4cYZPjxDjz9DFgychhG4BN0m8vjQOP1ds9jvPqnZw2tmcGCuim8c1lQDMAiYZXV+Vqrda31iFFb87fmsHv7ZlVXaUPJ2RJjz6a+LsD49eV2pSycatwM7Z4bM+DD7HJR+HvDQxfLwWP2bVxxBw3KSXNHGTlnH9VF/n11vWnkiNcPV4QbHpKd2Y5MKxU3eGLJ/ subkey 004FFE9C78916342 of key 46E96F6FF44F3D74 keygrip is 0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
      };

      programs.fish.enable = true;
      programs.zsh.enable = true;

      nixpkgs.config.allowUnfree = true;

      # Set available fonts
      fonts.packages = builtins.attrValues {
        nerdfonts = pkgs.nerdfonts.override { fonts = [ "DejaVuSansMono" ]; };
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
    }
    (mkIf my.users.tejing.pam {
      # unlock gpg keys with my login password
      security.pam.services = {
        login.gnupg.enable = true;
        login.gnupg.noAutostart = true;
        login.gnupg.storeOnly = true;
        lightdm-greeter.gnupg.enable = true;
        lightdm-greeter.gnupg.noAutostart = true;
        lightdm-greeter.gnupg.storeOnly = true;
        i3lock.gnupg.enable = true;
        i3lock.gnupg.noAutostart = true;
      };
    })
    (mkIf my.users.tejing.desktop {
      home-manager.users.tejing.imports = [ inputs.self.homeConfigurations.tejing.configurationModule ];

      # Enable touchpad support.
      # I actually just need this for the mouse acceleration settings that I'm used to.
      services.libinput.enable = true;
      services.libinput.mouse.accelSpeed = "0.6";

      programs.dconf.enable = true;

      systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

      # Start urxvtd with user sessions
      services.urxvtd.enable = true;
      services.urxvtd.package = pkgs.rxvt-unicode-emoji;
    })
    (mkIf my.users.tejing.network {
      # rtorrent peer & dht ports
      networking.firewall.allowedTCPPorts = [ 62813 ];
      networking.firewall.allowedUDPPorts = [ 62813 ];
    })
    (mkIf my.users.tejing.adb {
      programs.adb.enable = true;
      users.users.tejing.extraGroups = [ "adbusers" ];
    })
  ]);
}
