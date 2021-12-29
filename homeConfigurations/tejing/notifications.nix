{ config, my, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      dunst
    ;
  };

  xsession.windowManager.i3.config.keybindings = let
    mod = config.xsession.windowManager.i3.config.modifier;
  in {
    "${mod}+BackSpace"       = "exec --no-startup-id ${pkgs.dunst}/bin/dunstctl close";
    "${mod}+Shift+BackSpace" = "exec --no-startup-id ${pkgs.dunst}/bin/dunstctl close-all";
    "${mod}+backslash"       = "exec --no-startup-id ${pkgs.dunst}/bin/dunstctl history-pop";
    "${mod}+slash"           = "exec --no-startup-id ${pkgs.dunst}/bin/dunstctl context";
  };

  services.dunst.enable = true;
  services.dunst.settings = {
    global = {
      font = "Iosevka Term 11";
      markup = "full";
      format = "<b>%s</b>\\n%b";
      sort = false;
      alignment = "center";
      show_age_threshold = -1;
      word_wrap = true;
      hide_duplicate_count = true;
      width = 384;
      origin = "bottom-right";
      offset = "0x0";
      history_length = 15;
      line_height = 3;
      padding = 6;
      horizontal_padding = 6;
      separator_color = "frame";
      dmenu = "${pkgs.dmenu}/bin/dmenu";
      browser = my.scripts.mybrowser;
      icon_position = "left";
      max_icon_size = 80;
      frame_width = 1;
      fullscreen = "pushback";
    };
    urgency_low = {
      frame_color = "#007700";
      foreground = "#00FF00";
      background = "#000000";
      timeout = 4;
    };
    urgency_normal = {
      frame_color = "#00FF00";
      foreground = "#00FF00";
      background = "#000000";
      timeout = 6;
    };
    urgency_critical = {
      frame_color = "#FF0000";
      foreground = "#00FF00";
      background = "#000000";
      timeout = 8;
    };
  };
}
