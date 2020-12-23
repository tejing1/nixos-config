# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{nixpkgs, home-manager}: { config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      (import ./hardware-configuration.nix {inherit nixpkgs;})
      home-manager.nixosModules.home-manager
    ];

  nix = {
    # Use a version of nix with flake support
    package = pkgs.nixFlakes;
    # Use the new CLI and enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Hard link identical files in the store automatically
    autoOptimiseStore = true;
    # register the system's version of nixpkgs and home-manager
    registry.nixpkgs.flake = nixpkgs;
    registry.home-manager.flake = home-manager;
  };

  # Use /etc/profiles instead of ~/.nix-profile
  # In particular, this allows 'nixos-rebuild build-vm' and home-manager to work together
  home-manager.useUserPackages = true;

  # Use the system's nixpkgs instance
  home-manager.useGlobalPkgs = true;

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.loader.timeout = 1;
  # graphical boot progress display
  boot.plymouth.enable = true;
  # quiet boot
  boot.kernelParams = [ "quiet" ];

  networking.hostName = "tejingdesk"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "US/Pacific";

  # Enable NTP synchronization
  #services.ntp.enable = true; # superceded by systemd-timesyncd

  # Allow automatic upgrades, but never auto-reboot
  #system.autoUpgrade.enable = true;
  #system.autoUpgrade.allowReboot = false;

  # Enable Microsoft CoreFonts
  #fonts.enableCoreFonts = true; # OLD format
  fonts.fonts = with pkgs; [ corefonts nerdfonts ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    emacs
    mpd
    haskellPackages.git-annex
    lsof # needed for git-annex webapp
    rclone # used to connect git-annex to my phone's ftp server
    wireshark
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.fish.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Publish hostname via mdns and resolve *.local dns names via mdns
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;
  #services.avahi.publish.workstation = true;

  # hardcoded hosts entry for my Samsung A51 smartphone
  networking.hosts = { "192.168.0.104" = [ "phone.local" ];};

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.layout = "us";
  services.xserver.xkbOptions = "caps:none";

  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  #services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.desktopManager.plasma5.enable = true;

  # Enable i3.
  #services.xserver.windowManager.i3.enable = true;
  #services.xserver.windowManager.i3.package = pkgs.i3-gaps;

  # Have SDDM enable numlock on boot
  #services.xserver.displayManager.sddm.autoNumlock = true;

  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [
    # Proprietary NVIDIA driver
    "nvidia"
    # default list as a fallback (and for when I used "nixos-rebuild build-vm")
    "radeon"
    "cirrus"
    "vesa"
    "modesetting"
    ];
  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl ];
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiVdpau libvdpau-va-gl ];

  # Enable pulseaudio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  nixpkgs.config.pulseaudio = true;

  # Start emacs daemon with user sessions
  services.emacs.enable = true;

  # Start urxvtd with user sessions
  services.urxvtd.enable = true;

  # Start mpd service
  services.mpd.enable = true;
  services.mpd.musicDirectory = "/mnt/share/replaceable/music_database";
  services.mpd.startWhenNeeded = true;

  # Let the system-wide mpd service play to the per-user pulseaudio daemon via tcp
  hardware.pulseaudio.tcp.enable = true;
  hardware.pulseaudio.tcp.anonymousClients.allowedIpRanges = [ "127.0.0.1" ];
  services.mpd.extraConfig = ''
		audio_output {
		       type     "pulse"
		       name     "pulseaudio tcp on 127.0.0.1"
		       server   "127.0.0.1"
		}'';

  # Make emacsclient the default editor
  #services.emacs.defaultEditor = true;
  # ^ this doesn't do what I want (I need the -nw option), so I'm doing it myself:
  environment.variables.EDITOR = pkgs.emacs + "/bin/emacsclient -nw";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.tejing = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "audio" ];
    shell = pkgs.fish;
    hashedPassword = builtins.readFile ./pwhash.secret;
  };

  home-manager.users.tejing = {
    home.packages = with pkgs; [
      rxvt_unicode
      dunst
      feh
      xclip
      brave
      steam
      lutris
      mpv
      htop
      picom
      weechat
      xss-lock
      i3lock
      conky
      killall
      lxappearance
      mkpasswd
      nix-prefetch-github
      xorg.xev
      mkvtoolnix
      ffmpeg
      coq
      mpc_cli
      ncmpc
      alacritty
      starship # fancy prompts
      tmux
      git
      ruby
      unzip
      lshw
      pciutils
      wget
      fbreader
      youtube-dl
      pavucontrol
      ghc #perhaps this should be left to individual development environments?
      discord
      lastpass-cli

      # I don't think I need any of this wine stuff. Keeping it in a comment just in case
      #(wine.override { wineBuild = "wineWow"; wineRelease = "staging"; })
      #winetricks
      ## mono # Needed for some wine programs # maybe?
    ];
    xsession.enable = true;
    xsession.windowManager.i3.enable = true;
    xsession.windowManager.i3.config = let mod = "Mod4"; in {
      modifier = mod;
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
	"${mod}+Return" = "exec --no-startup-id ${pkgs.rxvt-unicode}/bin/urxvtc";
	"${mod}+Shift+q" = "kill";
	"${mod}+d" = "exec --no-startup-id ~/.config/i3/mydmenu_run";
	"${mod}+l" = "exec --no-startup-id \"${pkgs.coreutils}/bin/sleep 1; ${pkgs.xorg.xset}/bin/xset dpms force off\"";

	"${mod}+F1" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc prev";
	"${mod}+F2" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc toggle";
	"${mod}+F3" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc stop";
	"${mod}+F4" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc next";

	"${mod}+F5" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5% && ${pkgs.killall}/bin/killall -SIGUSR1 i3status";
	"${mod}+F6" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5% && ${pkgs.killall}/bin/killall -SIGUSR1 i3status";
	"${mod}+F7" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle && ${pkgs.killall}/bin/killall -SIGUSR1 i3status";

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
      assigns = {
	"12" = [{class = "^Brave-browser$";}];
	"10" = [{class = "^discord$";}];
	"8" = [{class = "^Steam$";}];
      };
      startup = [
        { command = "${pkgs.feh}/bin/feh --no-fehbg --bg-fill '${pkgs.plasma-workspace-wallpapers}/share/wallpapers/Path/contents/images/2560x1440.jpg'"; always = true; notification = false; }
        { command = "${pkgs.bash}/bin/bash -c \"${pkgs.killall}/bin/killall -w dunst; exec ${pkgs.dunst}/bin/dunst\""; always = true; notification = false; }
        { command = "${pkgs.bash}/bin/bash -c \"${pkgs.killall}/bin/killall -w picom; exec ${pkgs.picom}/bin/picom\""; always = true; notification = false; }
        { command = "${pkgs.xorg.xinput}/bin/xinput set-prop \"Logitech USB-PS/2 Optical Mouse\" \"libinput Accel Speed\" 0.6"; always = true; notification = false; }
        { command = "${pkgs.xss-lock}/bin/xss-lock -- ${pkgs.i3lock}/bin/i3lock -n -c 000000"; always = false; notification = false; }
        { command = "${pkgs.brave}/bin/brave"; always = false; notification = false; }
        { command = "${pkgs.discord}/bin/Discord"; always = false; notification = false; }
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
	    # Background color of the bar on the currently focused monitor output. If not used, the color will be taken from background.
	    focused_background #000000
	    # Text color to be used for the statusline on the currently focused monitor output. If not used, the color will be taken from statusline.
	    #focused_statusline
	    # Text color to be used for the separator on the currently focused monitor output. If not used, the color will be taken from separator.
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
      fonts = [ "DejaVuSansMono Nerd Font 8" ];
      workspaceAutoBackAndForth = true;
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
          format = " %volume";
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
	 format = "%Y-%m-%d %H:%M:%S";
	};
      };
    };
    programs.starship.enable = true;
    programs.starship.settings = {
      add_newline = false;
      prompt_order = [ "username" "hostname" "nix_shell" "git_branch" "git_commit" "git_state" "git_status" "directory" "cmd_duration" "jobs" "character" ];

      username = {
	user = "tejing";
	style_user = "bright-white bold";
	style_root = "bright-red bold";
      };
      hostname = {
	style = "bright-green bold";
	ssh_only = true;
      };
      nix_shell = {
	style = "bright-purple bold";
      };
      git_branch = {
	only_attached = true;
	style = "bright-yellow bold";
      };
      git_commit = {
	only_detached = true;
	style = "bright-yellow bold";
      };
      git_state = {
	style = "bright-purple bold";
      };
      git_status = {
	style = "bright-green bold";
      };
      directory = {
	prefix = "";
	truncation_length = 0;
      };
      cmd_duration = {
	prefix = "";
	style = "bright-blue";
      };
      jobs = {
	style = "bright-green bold";
      };
      character = {
	symbol = "$";
	error_symbol = "$";
      };
    };
    xsession.numlock.enable = true;
    programs.urxvt.enable = true;
    programs.urxvt.fonts = [ "xft:DejaVu Sans Mono:pixelsize=15" ];
    #programs.urxvt.fonts = [ "xft:DejaVu Sans Mono:pixelsize=15" "xft:DejaVuSansMono Nerd Font:pixelsize=15" ];
    #programs.urxvt.fonts = [ "xft:DejaVuSansMono Nerd Font:size=10" ];
    programs.urxvt.scroll.bar.enable = false;
    programs.urxvt.scroll.lines = 0;
    programs.urxvt.extraConfig = {
      background = "rgba:0000/0000/0000/C000";
      foreground = "#00ff00";
      depth = 32;
      internalBorder = 0;
    };
    xresources.properties = {
      "Xft.antialias" = 1;
      #"Xft.dpi" = 140;
      "Xft.rgba" = "rgb";
      "Xcursor.size" = 24;
      "Xcursor.theme" = "breeze_cursors";
    };
    home.stateVersion = "20.09";
  };

  # Set discard for filesystems that are (or might be) on the SSD 
  fileSystems."/".options = [ "defaults" "discard" ];
  fileSystems."/mnt/gentoo".options = [ "defaults" "discard" ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "17.09"; # Did you read the comment?

}
