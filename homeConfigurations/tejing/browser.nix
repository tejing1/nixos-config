{ config, lib, my, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.browser = mkOption {
    type = types.unspecified;
    description = "My preferred browser";
    visible = false;
    readOnly = true;
  };

  options.my.pwarun = mkOption {
    type = types.unspecified;
    description = "My preferred progressive web app runner";
    visible = false;
    readOnly = true;
  };

  config = {
    my.browser.pkg = pkgs.resholveScriptBin "mybrowser" {
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = [ my.scriptPkgs.mylaunch ];
      execer = [ "cannot:${my.scripts.mylaunch}" ]; # false. working around it with antiquoting
    } ''
      exec mylaunch app brave ${pkgs.brave}/bin/brave --no-first-run "$@"
    '';
    home.packages = builtins.attrValues {
      inherit (my.browser) pkg;
    };

    my.browser.outPath = "${my.browser.pkg}/bin/mybrowser";

    xdg.dataFile."mybrowser".source = my.browser;
    my.browser.link = "${config.xdg.dataHome}/mybrowser";
    home.sessionVariables.BROWSER = my.browser.link;

    my.pwarun.pkg = pkgs.resholveScriptBin "mypwarun" {
          interpreter = "${pkgs.bash}/bin/bash";
          inputs = [ my.browser.pkg ];
          execer = [ "cannot:${my.browser}" ];
    } ''
      exec mybrowser --app="$1"
    '';
    my.pwarun.outPath = "${my.pwarun.pkg}/bin/mypwarun";

    xsession.windowManager.i3.config.assigns."12" = [{ class = "^Brave-browser$"; instance = "^brave-browser$"; }];
    xsession.windowManager.i3.config.startup = [{ command = "${my.browser}"; always = false; notification = false; }];

    # install browserpass native host program for brave. the home-manager
    # option doesn't support brave, so I just copied what they were doing
    # for chromium from home-manager/modules/programs/browserpass.nix
    home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
    home.file.".config/BraveSoftware/Brave-Browser/policies/managed/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
  };
}
