{ pkgs, mylib, ... }:

{
  home.packages = with pkgs; [
    weechat
  ];
  xsession.windowManager.i3.config.startup = [
    { command = "${pkgs.rxvt-unicode}/bin/urxvtc -name weechat -e ${mylib.templateScript pkgs "mylaunch" scripts/mylaunch} app weechat ${pkgs.weechat}/bin/weechat"; always = false; notification = false; }
    { command = "${mylib.templateScript pkgs "mylaunch" scripts/mylaunch} app brave ${pkgs.brave}/bin/brave --app=https://discord.com/app";always = false; notification = false; }
    { command = "${mylib.templateScript pkgs "mylaunch" scripts/mylaunch} app brave ${pkgs.brave}/bin/brave --app=https://app.element.io";always = false; notification = false; }
  ];
  xsession.windowManager.i3.config.window.commands = [{ criteria = { class = "^URxvt$"; instance = "^weechat$"; }; command = "layout tabbed"; }];
  xsession.windowManager.i3.config.assigns."11" = [
    { class = "^Brave-browser$"; instance = "^discord.com__app$"; }
    { class = "^Brave-browser$"; instance = "^app.element.io$";   }
    { class = "^URxvt$"; instance = "^weechat$"; }
  ];
}
