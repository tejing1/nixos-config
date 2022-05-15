{ config, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      ledger
    ;
  };
  programs.emacs.enable = true;
  programs.emacs.extraPackages = epkgs: builtins.attrValues {
    inherit (epkgs)
      nix-mode
      haskell-mode
      ledger-mode
    ;
  };
  services.emacs.enable = true;

  home.sessionVariables.EDITOR = "${config.xdg.dataHome}/myeditor";
  xdg.dataFile."myeditor".source = pkgs.resholveScript "myeditor" {
    interpreter = "${pkgs.bash}/bin/bash";
    inputs = builtins.attrValues {
      inherit (pkgs) emacs;
    };
    execer = [ "cannot:${pkgs.emacs}/bin/emacsclient" ];
  } "exec emacsclient -t \"$@\"";

  xresources.properties = {
    "emacs.background" = "#000000";
    "emacs.foreground" = "#00FF00";
    "emacs.toolBar" = "off";
  };
}
