{ config, inputs, lib, my, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (my.lib) importSecret;

  myfeeds-plumber = my.lib.mkShellScript "myfeeds-plumber" {
    inputs = attrValues {
      inherit (pkgs) xdg-utils;
      mpv = config.programs.mpv.package;
    };
    execer = [
      "cannot:${pkgs.xdg-utils}/bin/xdg-open"
      "cannot:${config.programs.mpv.package}/bin/mpv"
    ];
  } ''
    case "$1" in
      https://www.youtube.com/watch\?*)
        mpv "$1" || { exitcode="$?"; read -rsN1 -p 'mpv failed, press enter to continue...'; echo; exit "$exitcode"; }
        ;;
      *)
        xdg-open "$1" &>/dev/null & disown;exit 0
        ;;
    esac
  '';

  myfeeds = my.lib.mkShellScript "myfeeds" {
    inputs = attrValues { inherit (pkgs) coreutils findutils inotify-tools sfeed; };
    execer = [ "cannot:${pkgs.sfeed}/bin/sfeed_curses" ];
    prologue = "${pkgs.writeText "set_sfeed_htmlconv.sh" ''
      export SFEED_HTMLCONV='${pkgs.lynx}/bin/lynx -stdin -dump -underline_links -image_links -display_charset="utf-8" -assume_charset="utf-8"'
      export SFEED_PLUMBER='${myfeeds-plumber}'
      export SFEED_PLUMBER_INTERACTIVE=1
    ''}";
  } ./myfeeds.sh;
in
{
  imports = [ inputs.self.homeModules.sfeed ];
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
