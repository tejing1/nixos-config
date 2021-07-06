{ config, pkgs, my, ... }:

{
  home.packages = with pkgs; [
    dunst
    xclip
  ];

  services.picom.enable = true;
  services.picom.backend = "xrender";
  services.picom.vSync = true;
  services.picom.opacityRule = [ "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'" ];

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
      markup = true;
      plain_text = false;
      format = "<b>%s</b>\\n%b";
      sort = false;
      alignment = "center";
      bounce_freq = 0;
      word_wrap = true;
      hide_duplicate_count = true;
      geometry = "384x5-0-0";
      history_length = 15;
      line_height = 3;
      padding = 6;
      horizontal_padding = 6;
      separator_color = "frame";
      dmenu = "${pkgs.dmenu}/bin/dmenu";
      browser = my.scripts.mybrowser;
      icon_position = "left";
      max_icon_size = 80;
      frame_width = 3;
      frame_color = "#8EC07C";
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

  gtk.enable = true;
  gtk.gtk3.bookmarks = [ "file:///home/tejing/data" ];
  gtk.font = { package = pkgs.nerdfonts; name = "DejaVuSansMono Nerd Font"; size = 8; };
  gtk.iconTheme = { package = pkgs.arc-icon-theme; name = "Arc"; };
  gtk.theme = { package = pkgs.arc-theme; name = "Arc-Dark"; };

  xsession.pointerCursor = { package = pkgs.numix-cursor-theme; name = "Numix-Cursor-Light"; size = 24; };
}
