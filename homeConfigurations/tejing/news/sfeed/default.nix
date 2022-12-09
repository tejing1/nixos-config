{ lib, my, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (my.lib) importSecret;

  myfeeds = my.lib.mkShellScript "myfeeds" {
    inputs = attrValues { inherit (pkgs) coreutils findutils inotify-tools sfeed; };
    execer = [ "cannot:${pkgs.sfeed}/bin/sfeed_curses" ];
  } ./myfeeds.sh;
in
{
  # Enable my sfeed module
  my.sfeed.enable = true;

  # Update every 30 mins
  my.sfeed.update = "*:00,30:00";

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
    pkgs.writeShellScript "myfeeds-cycle" "while true; do ${myfeeds};done"
  }"; always = false; notification = false; }];
}
