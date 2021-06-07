{ pkgs, my, ... }:

{
  home.packages = with pkgs; [
    feh # sets background images... but do I need it in my path?
    xss-lock
    i3lock
    xorg.xev # mainly useful for figuring out keybinds
  ];
  xsession.enable = true;
  xsession.numlock.enable = true;
  xsession.windowManager.i3.enable = true;
  xsession.windowManager.i3.config = let mod = "Mod4"; in {
    modifier = mod;
    defaultWorkspace = "workspace number 1";
    modes.resize = {
	    Left   = "resize shrink width 10 px or 1 ppt";
      Down   = "resize grow height 10 px or 1 ppt";
	    Up     = "resize shrink height 10 px or 1 ppt";
	    Right  = "resize grow width 10 px or 1 ppt";
	    Escape = "mode default";
	    Return = "mode default";
	    "${mod}+r" = "mode default";
    };
    keybindings = {
	    "${mod}+Shift+q" = "kill";
	    "${mod}+d" = "exec --no-startup-id ${my.templateScript pkgs "mydmenu_run" scripts/mydmenu_run}";
	    "--release ${mod}+l" = "exec --no-startup-id ${pkgs.xorg.xset}/bin/xset dpms force off";
      
	    "${mod}+Left" = "focus left";
	    "${mod}+Down" = "focus down";
	    "${mod}+Up" = "focus up";
	    "${mod}+Right" = "focus right";
      
	    "${mod}+Shift+Left" = "move left";
	    "${mod}+Shift+Down" = "move down";
	    "${mod}+Shift+Up" = "move up";
	    "${mod}+Shift+Right" = "move right";
      
	    "${mod}+h" = "split h";
	    "${mod}+v" = "split v";
	    "${mod}+f" = "fullscreen toggle";
      
	    "${mod}+s" = "layout stacking";
	    "${mod}+w" = "layout tabbed";
	    "${mod}+e" = "layout toggle split";
      
	    "${mod}+Shift+space" = "floating toggle";
	    "${mod}+space" = "focus mode_toggle";
      
	    "${mod}+a" = "focus parent";
      
	    "${mod}+1" = "workspace number 1";
	    "${mod}+2" = "workspace number 2";
	    "${mod}+3" = "workspace number 3";
	    "${mod}+4" = "workspace number 4";
	    "${mod}+5" = "workspace number 5";
	    "${mod}+6" = "workspace number 6";
	    "${mod}+7" = "workspace number 7";
	    "${mod}+8" = "workspace number 8";
	    "${mod}+9" = "workspace number 9";
	    "${mod}+0" = "workspace number 10";
	    "${mod}+minus" = "workspace number 11";
	    "${mod}+equal" = "workspace number 12";
      
	    "${mod}+Shift+1" = "move container to workspace number 1";
	    "${mod}+Shift+2" = "move container to workspace number 2";
	    "${mod}+Shift+3" = "move container to workspace number 3";
	    "${mod}+Shift+4" = "move container to workspace number 4";
	    "${mod}+Shift+5" = "move container to workspace number 5";
	    "${mod}+Shift+6" = "move container to workspace number 6";
	    "${mod}+Shift+7" = "move container to workspace number 7";
	    "${mod}+Shift+8" = "move container to workspace number 8";
	    "${mod}+Shift+9" = "move container to workspace number 9";
	    "${mod}+Shift+0" = "move container to workspace number 10";
	    "${mod}+Shift+underscore" = "move container to workspace number 11";
	    "${mod}+Shift+plus" = "move container to workspace number 12";
      
	    "${mod}+Shift+c" = "reload";
	    "${mod}+Shift+r" = "restart";
	    "${mod}+Shift+e" = "exec \"${pkgs.i3}/bin/i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' '${pkgs.i3}/bin/i3-msg exit'\"";
	    "${mod}+r" = "mode resize";
    };
    startup = [
      { command = "${pkgs.feh}/bin/feh --no-fehbg --bg-fill '${pkgs.plasma-workspace-wallpapers}/share/wallpapers/Path/contents/images/2560x1440.jpg'"; always = true; notification = false; }
      { command = "${pkgs.xorg.xinput}/bin/xinput set-prop \"Logitech USB-PS/2 Optical Mouse\" \"libinput Accel Speed\" 0.6"; always = true; notification = false; }
      { command = "${pkgs.xss-lock}/bin/xss-lock -- ${pkgs.i3lock}/bin/i3lock -n -c 000000"; always = false; notification = false; }
    ];
    bars = [{
      statusCommand = "${pkgs.i3status}/bin/i3status";
	    position = "top";
	    colors = {
        # Background color of the bar.
	      background = "#101010";
	      # Text color to be used for the statusline.
	      statusline = "#00ff00";
	      # Text color to be used for the separator.
	      separator = "#008080";
	      # Border, background and text color for a workspace button when the workspace has focus.
	      focusedWorkspace = {border = "#008000"; background = "#000000"; text = "#008000";};
	      # Border, background and text color for a workspace button when the workspace is active (visible) on some output, but the focus is on another one.
	      # You can only tell this apart from the focused workspace when you are using multiple monitors.
	      activeWorkspace = {border = "#004020"; background = "#101010"; text = "#008000";};
	      # Border, background and text color for a workspace button when the workspace does not have focus and is not active (visible) on any output. This will be the case for most workspaces.
	      inactiveWorkspace = {border = "#000000"; background = "#202020"; text = "#008000";};
	      # Border, background and text color for a workspace button when the workspace contains a window with the urgency hint set.
	      urgentWorkspace = {border = "#800080"; background = "#202020"; text = "#008000";};
	      # Border, background and text color for the binding mode indicator. If not used, the colors will be taken from urgent_workspace.
	      bindingMode = {border = "#000000"; background = "#000000"; text = "#00ffff";};
	    };
	    extraConfig = ''
	  colors {      
	    # Background   color of the bar on the currently focused monitor output. If not used, the color will be taken from background.
	    focused_background #000000
	    # Text color to      be used for the statusline on the currently focused monitor output. If not used, the color will be taken from statusline.
	    #focused_statusline  
	    # Text color to be us ed for the separator on the currently focused monitor output. If not used, the color will be taken from separator.
	    #focused_separator 
	  }
	''; 
    }];
    colors = {
      background      = "#000000";
	    focused         = {border = "#00ff00"; background = "#000000"; text = "#00ff00"; indicator = "#00ff00"; childBorder = "#008000";};
	    focusedInactive = {border = "#008040"; background = "#101010"; text = "#00ff00"; indicator = "#008040"; childBorder = "#004020";};
	    unfocused       = {border = "#000000"; background = "#202020"; text = "#00ff00"; indicator = "#000000"; childBorder = "#000000";};
	    urgent          = {border = "#ff00ff"; background = "#202020"; text = "#00ff00"; indicator = "#ff00ff"; childBorder = "#800080";};
	    placeholder     = {border = "#000000"; background = "#202020"; text = "#00ff00"; indicator = "#000000"; childBorder = "#000000";};
    };
    window = {
      border = 1;
	    titlebar = false;
      hideEdgeBorders = "smart";
      #commands = [];
    };
    floating = {
      border = 1;
	    titlebar = false;
    };
    fonts = {
      names = [ "DejaVuSansMono Nerd Font" ];
      size = 8.0;
    };
    workspaceAutoBackAndForth = false;
    workspaceLayout = "default";
  };
  programs.i3status = {
    enable = true;
    enableDefault = false;
    general = {
      colors = true;
	    markup = "pango";
	    separator = "";
	    interval = 1;
	    color_good     = "#00FF00";
	    color_degraded = "#FFFF00";
	    color_bad      = "#FF0000";
    };
    modules = {
      "volume master".position = 1;
      "volume master".settings = {
        format = "墳 %volume";
	      format_muted = "婢 %volume";
	      device = "pulse";
	      color_degraded = "#FF0000";
	    };
	    "ethernet _first_".position = 2;
	    "ethernet _first_".settings = {
	      format_up = " %ip";
	      format_down = "";
	    };
	    "disk /".position = 3;
	    "disk /".settings = {
	      format = "/:%percentage_used";
	      format_not_mounted = "<span foreground='#ff0000'>/:not mounted !?!</span>";
	      threshold_type = "percentage_avail";
	      low_threshold = "25";
	    };
	    "cpu_usage".position = 4;
	    "cpu_usage".settings = {
	      format = "CPU:%usage";
	      degraded_threshold = 60;
	      max_threshold = 90;
	      separator = false;
	    };
	    "cpu_temperature 0".position = 5;
	    "cpu_temperature 0".settings = {
	      format = "%degrees°C";
	      max_threshold = 80;
	      path = "/sys/devices/platform/coretemp.0/hwmon/hwmon0/temp1_input";
	    };
	    "memory".position = 6;
	    "memory".settings = {
	      format = "RAM:%used";
	      format_degraded = "RAM:%used(%available left)";
	      threshold_critical = "10%";
	      threshold_degraded = "25%";
	    };
	    "time".position = 6;
	    "time".settings = {
	      format = "%Y-%m-%d %a %H:%M:%S";
	    };
    };
  };
}
