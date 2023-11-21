{ config, my, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ledger
    ;
  };
  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs29;
  programs.emacs.extraPackages = epkgs: builtins.attrValues {
    inherit (epkgs)
      nix-mode
      haskell-mode
      ledger-mode
    ;
  };
  services.emacs.enable = true;

  home.sessionVariables.EDITOR = "${config.xdg.dataHome}/myeditor";
  xdg.dataFile."myeditor".source = my.lib.mkShellScript "myeditor" {
    inputs = [ pkgs.emacs ];
    execer = [ "cannot:${pkgs.emacs}/bin/emacsclient" ];
  } "exec emacsclient -t \"$@\"";

  xresources.properties = {
    "emacs.background" = "#000000";
    "emacs.foreground" = "#00FF00";
    "emacs.toolBar" = "off";
  };
}
