{ my, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      newsboat
    ;
  };
  xsession.windowManager.i3.config.assigns."10" = [{class = "^URxvt$";instance = "^newsboat$";}];
  xsession.windowManager.i3.config.startup = [{ command = "${my.launch.term} app newsboat ${pkgs.newsboat}/bin/newsboat"; always = false; notification = false; }];
}
