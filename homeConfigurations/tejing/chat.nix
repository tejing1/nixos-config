{ lib, my, pkgs, pkgsUnstable, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      weechat
    ;
    inherit (pkgsUnstable)
      signal-desktop
    ;
  };
  xsession.windowManager.i3.config.startup = [
    { command = "${my.launch.term} app weechat ${pkgs.weechat}/bin/weechat"; always = false; notification = false; }
    { command = "${my.pwarun} discord https://discord.com/app";always = false; notification = false; }
    { command = "${my.pwarun} element https://app.element.io";always = false; notification = false; }
    { command = "${my.pwarun} discourse https://discourse.nixos.org/latest";always = false; notification = false; }
    { command = "${my.launch} app signal ${lib.getExe pkgsUnstable.signal-desktop}";always = false; notification = false; }
  ];
  xsession.windowManager.i3.config.window.commands = [{ criteria = { class = "^URxvt$"; instance = "^weechat$"; }; command = "layout tabbed"; }];
  xsession.windowManager.i3.config.assigns."11" = [
    { class = "^discord$"; instance = "^discord$"; }
    { class = "^element$"; instance = "^element$"; }
    { class = "^discourse$"; instance = "^discourse$"; }
    { class = "^URxvt$"; instance = "^weechat$"; }
    { class = "^Signal$"; instance = "^signal$"; }
  ];
}
