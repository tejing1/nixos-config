{ config, inputs, lib, my, pkgs, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (my.lib) readSecret;
in
{
  options.my.users.tejing = mkEnableOption "user \"tejing\"";
  config = mkIf my.users.tejing {
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

  };
}
