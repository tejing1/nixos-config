{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ledger
  ];
  programs.emacs.enable = true;
  programs.emacs.extraPackages = (epkgs: with epkgs; [ nix-mode haskell-mode ledger-mode ]);
  services.emacs.enable = true;
  home.sessionVariables.EDITOR = pkgs.emacs + "/bin/emacsclient -nw";
  xresources.properties = {
    "emacs.background" = "#000000";
    "emacs.foreground" = "#00FF00";
    "emacs.toolBar" = "off";
  };
}
