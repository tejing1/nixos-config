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
    # Make builds run with low priority so my system stays responsive
    daemonNiceLevel = 19;
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

  environment.systemPackages = with pkgs; [
    # Needed to work with my flake
    git git-crypt
  ];
}
