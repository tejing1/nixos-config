{ my, pkgs, ...}:

let
  steam-pr-overlay = final: prev: {
    steam = (
      import (
        final.fetchFromGitHub {
          owner = "jonringer";
          repo = "nixpkgs";
          rev = "d536e0a0eb54ea51c676869991fe5a1681cc6302";
          sha256 = "sha256-733fLqgkYUPK7jQxXkQihzihkiTtQG/vcV/ZyuDz86Y=";
        }
      ) {
        inherit (final) system;
        config.allowUnfree = true;
      }
    ).steam;
  };
in
{
  nixpkgs.overlays = [ steam-pr-overlay my.overlays.steam-fix-screensaver ];
  programs.steam.enable = true;
}
