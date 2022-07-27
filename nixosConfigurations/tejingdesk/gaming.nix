{ my, pkgs, ...}:

let
  steam-pr = fetchTree {
    type = "github";
    owner = "jonringer";
    repo = "nixpkgs";
    rev = "d536e0a0eb54ea51c676869991fe5a1681cc6302";
    narHash = "sha256-733fLqgkYUPK7jQxXkQihzihkiTtQG/vcV/ZyuDz86Y=";
  };

  steam-pr-overlay = final: prev: {
    steam = (
      import steam-pr {
        inherit (final) system;
        config.allowUnfree = true;
      }
    ).steam;
  };
in
{
  nixpkgs.overlays = [
    # use steam from jonringer's pr rather than main nixpkgs
    steam-pr-overlay

    # keep steam from inhibiting the screensaver
    my.overlays.steam-fix-screensaver
  ];

  programs.steam.enable = true;

  # Save the fetchTree result as a dependency of the system generation
  # so we don't need to repeatedly download it.
  system.extraDependencies = [ steam-pr ];
}
