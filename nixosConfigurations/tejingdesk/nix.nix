{ config, my, pkgs, ... }:

{
  nixpkgs.overlays = [
    # make `nix repl` handle home and end keys in urxvt properly
    my.overlays.editline-urxvt-home-end-fix
  ];

  nix = {
    # Use the new CLI and enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Make builds run with low priority so my system stays responsive
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    # Hard link identical files in the store automatically
    autoOptimiseStore = true;
    # automatically trigger garbage collection
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      # Needed to work with my flake
      git git-crypt
    ;
  };
}
