{ pkgs, ... }:

{
  home.packages = with pkgs; [
    weechat
  ];
  xsession.windowManager.i3.config.assigns."10" = [{ class = "^Brave-browser$"; instance = "^discord.com__app$"; }
                                                   { class = "^Brave-browser$"; instance = "^app.element.io$";   }];
  xsession.windowManager.i3.config.assigns."11" = [{ class = "^URxvt$"; instance = "^weechat$"; }];
  xsession.windowManager.i3.config.startup = [{ command = "${pkgs.rxvt-unicode}/bin/urxvtc -name weechat -e weechat"; always = false; notification = false; }];
}
