{ config, inputs, lib, my, pkgs, ... }:
let
  inherit (lib) mkOption types escapeShellArg;
  inherit (my.lib) mkShellScript;
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
    my.browser = mkShellScript "mybrowser" {
      inputs = [ my.launch.pkg ];
      execer = [ "cannot:${my.launch}" ]; # false. working around it with antiquoting
    } ''
      exec mylaunch app vieb ${inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.vieb}/bin/vieb "$@"
    '';
    home.packages = builtins.attrValues {
      inherit (pkgs) brave;
      inherit (inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}) vieb;
      mybrowser = my.browser.pkg;
      mypwarun = my.pwarun.pkg;
    };

    xdg.dataFile."mybrowser".source = my.browser;
    home.sessionVariables.BROWSER = "${config.xdg.dataHome}/mybrowser";
    xdg.desktopEntries.mybrowser = {
      name = "My Browser";
      genericName = "Web Browser";
      exec = "${my.browser} %U";
      terminal = false;
      mimeType = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "text/html" = "mybrowser.desktop";
      "x-scheme-handler/http" = "mybrowser.desktop";
      "x-scheme-handler/https" = "mybrowser.desktop";
    };

    my.pwarun = mkShellScript "mypwarun" {
          inputs = [ my.launch.pkg pkgs.coreutils pkgs.jo ];
          execer = [ "cannot:${my.launch}" ]; # false. working around it with antiquoting
    } ''
      name="$1"
      url="$2"
      dir=${escapeShellArg config.xdg.configHome}/mypwarun/"$name"
      mkdir -p "$dir/datafolder"
      jo -- -s name="$name" apps="$(jo -a "$(jo -- container=main url="$url")")" > "$dir/erwic.json"
      cat <<EOF >"$dir/viebrc"
      set guitabbar=never
      set guinavbar=onupdate
      set menupage=globalasneeded
      imapclear!
      imap <A-F4> <:quitall>
      imap <C-A-n> <toNormalMode>
      call <toInsertMode>
      EOF
      exec mylaunch app "pwarun-$name" ${inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.vieb}/bin/vieb --erwic="$dir/erwic.json" --datafolder="$dir/datafolder" --config-file="$dir/viebrc"
    '';

    xsession.windowManager.i3.config.assigns."12" = [{ class = "^Vieb$"; instance = "^vieb$"; }];
    xsession.windowManager.i3.config.startup = [{ command = "${my.browser}"; always = false; notification = false; }];

    # install browserpass native host program for brave. the home-manager
    # option doesn't support brave, so I just copied what they were doing
    # for chromium from home-manager/modules/programs/browserpass.nix
    home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
    home.file.".config/BraveSoftware/Brave-Browser/policies/managed/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
  };
}
