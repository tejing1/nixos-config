{ my, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (my.scriptPkgs)
      mybrowser
    ;
  };
  xsession.windowManager.i3.config.assigns."12" = [{ class = "^Brave-browser$"; instance = "^brave-browser$"; }];
  xsession.windowManager.i3.config.startup = [{ command = my.scripts.mybrowser; always = false; notification = false; }];

  # install browserpass native host program for brave. the home-manager
  # option doesn't support brave, so I just copied what they were doing
  # for chromium from home-manager/modules/programs/browserpass.nix
  home.file.".config/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
  home.file.".config/BraveSoftware/Brave-Browser/policies/managed/com.github.browserpass.native.json".source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
}
