{ config, lib, my, pkgs, ... }:
let
  inherit (my.lib) mkShellScript;
in
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      xclip
    ;
    inherit (pkgs.xorg)
      xev # mainly useful for figuring out keybinds
    ;
  };
  systemd.user.services.xss-lock = {
    Unit = {
      Description = "xss-lock, session locker service";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    # It's important that the screensaver fully locks before dpms engages... otherwise it doesn't seem to lock at all :-/
    # since dpms is set to engage at 600 seconds, I have it set to notify at 530 seconds and lock at 530+60=590 seconds
    Service.ExecStartPre = "-${pkgs.xorg.xset}/bin/xset s 530 60";
    Service.ExecStart = "${pkgs.xss-lock}/bin/xss-lock -n ${
      mkShellScript "mylocknotify" {
        inputs = builtins.attrValues {
          inherit (pkgs) feh;
        };
        execer = [ "cannot:${pkgs.feh}/bin/feh" ];
      } ''
        exec feh -F /mnt/persist/tejing/wallpapers/lockscreen.png
      ''
    } -s \${XDG_SESSION_ID} -- ${
      mkShellScript "mylockcmd" {
        inputs = builtins.attrValues {
          inherit (pkgs) dbus dunst systemd i3lock;
          inherit (pkgs.xorg) xset;
        };
        execer = [
          "cannot:${pkgs.systemd}/bin/systemctl"
          "cannot:${pkgs.dunst}/bin/dunstctl"
        ];
      } ''
        fixsettings () {
            PATH="${pkgs.dbus}/bin''${PATH:+:$PATH}" dunstctl set-paused false
            xset dpms 0 0 600
            systemctl --user start passphrases.service
        }
        cleanquit () {
            fixsettings
            kill %1
        }
        trap cleanquit HUP INT TERM
        i3lock -n -i /mnt/persist/tejing/wallpapers/lockscreen.png &
        PATH="${pkgs.dbus}/bin''${PATH:+:$PATH}" dunstctl set-paused true
        xset dpms 0 0 15
        systemctl --user stop passphrases.service
        while ! wait;do true;done
        fixsettings
      ''
    }";
  };
  systemd.user.services.set-desktop-background = {
    Unit = {
      Description = "Set the desktop background using feh --bg-fill";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service.Type = "oneshot";
    Service.RemainAfterExit = true;
    Service.ExecStart = "${pkgs.feh}/bin/feh --no-fehbg --bg-fill /mnt/persist/tejing/wallpapers/background";
  };
  xsession.enable = true;
  xsession.numlock.enable = true;
  xsession.windowManager.i3.enable = true;
  xsession.windowManager.command = lib.mkForce "${my.launch} app i3 ${config.xsession.windowManager.i3.package}/bin/i3";
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
      "${mod}+d" = "exec --no-startup-id ${
        mkShellScript "mydmenu_run" {
          inputs = builtins.attrValues {
            inherit (pkgs) coreutils dmenu;
            mylaunch = my.launch.pkg;
          };
          execer = [ "cannot:${my.launch}" ]; # false, but doesn't matter in this case
        } ''
          function docmd {
              exec mylaunch progs "$(basename $1)" "$@"
          }

          docmd $(dmenu_path | dmenu "$@")
        ''
      }";
      "${mod}+l" = "exec --no-startup-id ${pkgs.systemd}/bin/loginctl lock-session";
      "${mod}+o" = "exec --no-startup-id ${
        mkShellScript "myclipopen" {
          inputs = builtins.attrValues {
            inherit (pkgs) xclip i3;
            mybrowser = my.browser.pkg;
          };
          execer = [ "cannot:${my.browser}" ];
        } ''
          mybrowser -- "$(xclip -o -t UTF8_STRING -selection primary)" && i3-msg 'workspace number 12'
        ''
      }";

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
      "${mod}+Shift+e" = "exec --no-startup-id ${
        mkShellScript "myi3exit" [ pkgs.i3 ] ''
          dir="/run/user/$(id -u)/myi3exit"
          stamp="$dir/stamp"
          tempstamp="$dir/tempstamp"
          mkdir -p "$dir"
          touch -d '2 sec ago' "$tempstamp"
          if test "$stamp" -nt "$tempstamp"; then
              i3-msg exit
          else
              touch "$stamp"
          fi
          rm "$tempstamp"
        ''
      }";
      "${mod}+r" = "mode resize";
    };
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
        # Background color of the bar on the currently focused monitor output. If not used, the color will be taken from background.
        focusedBackground = "#000000";
        # Text color to be used for the statusline on the currently focused monitor output. If not used, the color will be taken from statusline.
        focusedStatusline = null;
        # Text color to be used for the separator on the currently focused monitor output. If not used, the color will be taken from separator.
        focusedSeparator = null;
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
      names = [ "DejaVuSansM Nerd Font" ];
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
        format = "󰕾 %volume";
        format_muted = "󰖁 %volume";
        device = "pulse";
        color_degraded = "#FF0000";
      };
      "ethernet _first_".position = 2;
      "ethernet _first_".settings = {
        format_up = "󰈁 %ip";
        format_down = "󰈂";
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

  services.picom.enable = true;
  services.picom.backend = "xrender";
  services.picom.vSync = true;
  services.picom.opacityRules = [ "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'" ];

  gtk.enable = true;
  gtk.gtk3.bookmarks = [ "file:///home/tejing/data" ];
  gtk.font = { package = pkgs.nerdfonts.override { fonts = [ "DejaVuSansMono" ]; }; name = "DejaVuSansM Nerd Font"; size = 8; };
  gtk.iconTheme = { package = pkgs.arc-icon-theme; name = "Arc"; };
  gtk.theme = { package = pkgs.arc-theme; name = "Arc-Dark"; };

  home.pointerCursor = { package = pkgs.numix-cursor-theme; name = "Numix-Cursor-Light"; size = 24; x11.enable = true; };
}
