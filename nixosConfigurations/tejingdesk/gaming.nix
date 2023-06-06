{ my, ...}:

{
  nixpkgs.overlays = [
    # keep steam from inhibiting the screensaver
    my.overlays.steam-fix-screensaver
  ];

  programs.steam.enable = true;
}
