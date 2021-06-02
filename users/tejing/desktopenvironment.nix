{ pkgs, ... }:

{
  home.packages = with pkgs; [
    dunst
    xclip
  ];

  services.picom.enable = true;
  services.picom.backend = "xrender";
  services.picom.vSync = true;
  services.picom.opacityRule = [ "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'" ];

  services.dunst.enable = true;
  services.dunst.settings = {
    global = {
      font = "Iosevka Term 11";
      markup = true;
      plain_text = false;
      format = "<b>%s</b>\\n%b";
      sort = false;
      alignment = "center";
      bounce_freq = 0;
      word_wrap = true;
      hide_duplicate_count = true;
      geometry = "384x5+0-0";
      history_length = 15;
      line_height = 3;
      padding = 6;
      horizontal_padding = 6;
      separator_color = "frame";
      startup_notification = true;
      dmenu = "${pkgs.dmenu}/bin/dmenu";
      browser = "${pkgs.brave}/bin/brave";
      icon_position = "left";
      max_icon_size = 80;
      frame_width = 3;
      frame_color = "#8EC07C";
    };
    # DEPRECATED: define keybindings and should be handled through i3 calling dunstctl
    shortcuts = {
      close = "ctrl+space";
      close_all = "ctrl+shift+space";
      history = "ctrl+grave";
      context = "ctrl+shift+period";
    };
    urgency_low = {
      frame_color = "#3B7C87";
      foreground = "#3B7C87";
      background = "#191311";
      timeout = 4;
    };
    urgency_normal = {
      frame_color = "#5B8234";
      foreground = "#5B8234";
      background = "#191311";
      timeout = 6;
    };
    urgency_critical = {
      frame_color = "#B7472A";
      foreground = "#B7472A";
      background = "#191311";
      timeout = 8;
    };
    fullscreen = {
      fullscreen = "pushback";
    };
  };
  xresources.properties = {
    "Xcursor.size" = 24;
    "Xcursor.theme" = "breeze_cursors";
  };
}
