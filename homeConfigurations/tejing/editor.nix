{ config, my, pkgs, ... }:

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
      python-mode
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
    "emacsOrgAgenda.background" = "#000000";
    "emacsOrgAgenda.foreground" = "#00FF00";
    "emacsOrgAgenda.toolBar" = "off";
  };

  xsession.windowManager.i3.config.assigns."10" = [{class = "^Emacs$";instance = "^emacsOrgAgenda$";}];
  xsession.windowManager.i3.config.startup = [{ command = "${my.launch} app emacs-org-agenda ${pkgs.writeShellScript "emacs-org-agenda-cycle" ''while true; do emacsclient -cF '((name . "emacsOrgAgenda"))' --eval '(org-agenda "" "n")';done''}"; always = false; notification = false; }];
}
