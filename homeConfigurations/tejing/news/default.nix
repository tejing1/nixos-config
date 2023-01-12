{ lib, my, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (my.lib) importSecret;

  myfeeds = my.lib.mkShellScript "myfeeds" {
    inputs = attrValues { inherit (pkgs) coreutils findutils inotify-tools sfeed; };
    execer = [ "cannot:${pkgs.sfeed}/bin/sfeed_curses" ];
    prologue = "${pkgs.writeText "set_sfeed_htmlconv.sh" ''export SFEED_HTMLCONV='${pkgs.lynx}/bin/lynx -stdin -dump -underline_links -image_links -display_charset="utf-8" -assume_charset="utf-8"' ''}";
  } ./myfeeds.sh;
in
{
  # Enable my sfeed module
  my.sfeed.enable = true;

  # Update every hour, at a non-round time
  my.sfeed.update = "*:45:35";

  # Pass useful args through to submodule config
  my.sfeed.rc._module.args = { inherit pkgs my; };
  my.sfeed.rc.imports = [

    # Public config, including some useful site-specific code
    ./rc.public.nix

    # Private config, including most of the actual feeds.<name> values
    (importSecret {} ./rc.secret.nix)

  ];

  home.packages = [ myfeeds.pkg ];

  xsession.windowManager.i3.config.assigns."10" = [{class = "^URxvt$";instance = "^myfeeds$";}];
  xsession.windowManager.i3.config.startup = [{ command = "${my.launch.term} app myfeeds ${
    pkgs.writeShellScript "myfeeds-cycle" "while true; do myfeeds;done"
  }"; always = false; notification = false; }];
}
