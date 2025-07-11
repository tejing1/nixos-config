{ config, lib, my, pkgs, ... }:
let
  inherit (builtins) concatStringsSep isBool isInt;
  inherit (lib) mkOption types escapeShellArg mapAttrsToList mapAttrs' nameValuePair;
  inherit (my.lib) mkShellScript importSecret;
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
      exec mylaunch app vieb ${my.pkgsUnstable.vieb}/bin/vieb "$@"
    '';
    home.packages = builtins.attrValues {
      inherit (pkgs) brave;
      inherit (my.pkgsUnstable) vieb;
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
    xdg.configFile."mimeapps.list".force = true;
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
      set mouse-=guiontop
      set menupage=globalasneeded
      set windowtitle=%title
      set nativetheme=dark
      imapclear!
      imap <A-F4> <:quitall>
      imap <C-A-n> <toNormalMode>
      imap <C-A-r> <refreshTab>
      imap <C-A-f> <startFollowNewTab>
      call <toInsertMode>
      EOF
      exec mylaunch app "pwarun-$name" ${my.pkgsUnstable.vieb}/bin/vieb --erwic="$dir/erwic.json" --datafolder="$dir/datafolder" --config-file="$dir/viebrc"
    '';

    home.file = {
      ".vieb/viebrc".text = concatStringsSep "\n" (
        mapAttrsToList (n: v:
          if isBool v then
            "set ${if v then "" else "no"}${n}"
          else if isInt v then
            "set ${n}=${toString v}"
          else
            "set ${n}=${v}"
        ) {
          adblocker = "update";
          downloadmethod = "confirm";
          downloadpath = "${config.home.homeDirectory}/data/";
          follownewtabswitch = false;
          suspendbackgroundtab = false;
          tabcycle = false;
          tabreopenposition = "previous";
          dialogconfirm = "show";
          nativetheme = "dark";
          notificationforpermissions = "all";
          useragent = "%default";
          userscript = true;
          userscriptscope = ''["page","file"]'';
          vimcommand = ''"emacsclient -c"'';
          pdfbehavior = "view";
          suggesttopsites = 0;
        } ++ map (x: "unmap ${x}") [
        ] ++ mapAttrsToList (n: v:
          "nmap ${n} ${v}"
        ) {
          "j" = "<scrollPageDownHalf>";
          "k" = "<scrollPageUpHalf>";
        });
      # install browserpass native host program for brave. the home-manager
      # option doesn't support brave, so I just copied what they were doing
      # for chromium from home-manager/modules/programs/browserpass.nix
      ".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
      ".config/BraveSoftware/Brave-Browser/policies/managed/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
    } // mapAttrs' (n: v: nameValuePair ".vieb/userscript/${n}.js" { text = v; })
      (importSecret {} ./userscripts.secret.nix
       // {
         global = ''
           // workaround for vieb injecting css into local html files
           if (/^file:/.exec(window.location.href)) {
               setTimeout(() =>
                   document.querySelectorAll("html > head > style#default-styling").forEach((x) => x.outerHTML = "")
                   , 10);
           }
           // mark common patterns for previous and next buttons so vieb notices them
           document.querySelectorAll("a.btn-prev").forEach((x) => x.setAttribute("rel", "prev"))
           document.querySelectorAll("a.btn-next").forEach((x) => x.setAttribute("rel", "next"))
         '';
       });

    xsession.windowManager.i3.config.assigns."12" = [{ class = "^Vieb$"; instance = "^vieb$"; }];
    xsession.windowManager.i3.config.startup = [{ command = "${my.browser}"; always = false; notification = false; }];

  };
}
