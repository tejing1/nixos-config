{ my, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      weechat
    ;
  };
  xsession.windowManager.i3.config.startup = [
    { command = "${my.scripts.mylaunchterm} app weechat ${pkgs.weechat}/bin/weechat"; always = false; notification = false; }
    { command = "${my.pwarun} https://discord.com/app";always = false; notification = false; }
    { command = "${my.pwarun} https://app.element.io";always = false; notification = false; }
  ];
  xsession.windowManager.i3.config.window.commands = [{ criteria = { class = "^URxvt$"; instance = "^weechat$"; }; command = "layout tabbed"; }];
  xsession.windowManager.i3.config.assigns."11" = [
    { class = "^Brave-browser$"; instance = "^discord.com__app$"; }
    { class = "^Brave-browser$"; instance = "^app.element.io$";   }
    { class = "^URxvt$"; instance = "^weechat$"; }
  ];
}
