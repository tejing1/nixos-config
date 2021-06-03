{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    htop
    killall
    mkpasswd
    tmux
    git
    unzip
    lshw
    pciutils
    wget
    lastpass-cli
    ranger
    youtube-dl
    mkvtoolnix
    ffmpeg
    nix-prefetch-github
  ];
  programs.fish.enable = true;
  programs.dircolors.enableFishIntegration = true;
  programs.starship.enableFishIntegration = true;
  programs.fish.loginShellInit = ''
    cd ~/data
  '';
  programs.fish.shellInit = ''
    set fish_greeting '''
  '';
  programs.fish.shellAliases = {
    # shortcuts for ls
    ls = "ls --color=auto --hide=\\*~ --hide=lost+found";
    ll = "ls -l";
    la = "ls -A";
    lla = "ls -lA";
    # I'm never going to learn to actually type 'emacsclient'...
    emacs = "emacsclient -nw";
    xemacs = "emacsclient -c";
    # No clobbering on mv please
    mv = "mv -i";
    # Only show the filesystems I actually care about in df
    df = "df -x tmpfs -x devtmpfs -x fuse.portal";
    # use sudo where appropriate
    lvm = "sudo lvm";
  };
  
  programs.bash.enable = true;
  programs.dircolors.enableBashIntegration = true;
  programs.starship.enableBashIntegration = true;
  programs.bash.shellAliases = config.programs.fish.shellAliases;

  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = false;
    format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";
    shlvl = {
      disabled = false;
      symbol = "ﰬ";
      style = "bright-red bold";
    };
    shell = {
      disabled = false;
      format = "$indicator";
      fish_indicator = "";
      bash_indicator = "[BASH](bright-white) ";
    };
    username = {
	    style_user = "bright-white bold";
	    style_root = "bright-red bold";
    };
    hostname = {
	    style = "bright-green bold";
	    ssh_only = true;
    };
    nix_shell = {
      symbol = "";
      format = "[$symbol$name]($style) ";
	    style = "bright-purple bold";
    };
    git_branch = {
	    only_attached = true;
      format = "[$symbol$branch]($style) ";
      symbol = "שׂ";
	    style = "bright-yellow bold";
    };
    git_commit = {
	    only_detached = true;
      format = "[ﰖ$hash]($style) ";
	    style = "bright-yellow bold";
    };
    git_state = {
	    style = "bright-purple bold";
    };
    git_status = {
	    style = "bright-green bold";
    };
    directory = {
      read_only = " ";
	    truncation_length = 0;
    };
    cmd_duration = {
	    format = "[$duration]($style) ";
	    style = "bright-blue";
    };
    jobs = {
	    style = "bright-green bold";
    };
    character = {
	    success_symbol = "[\\$](bright-green bold)";
	    error_symbol = "[\\$](bright-red bold)";
    };
  };
  programs.dircolors.enable = true;
  programs.dircolors.extraConfig = ''
    TERM alacritty
  '';
  programs.dircolors.settings = {
    ".iso" = "01;31"; # .iso files bold red like .zip and other archives
    ".gpg" = "01;33"; # .gpg files bold yellow
    # Images to non-bold magenta instead of bold magenta like videos
    ".bmp"   = "00;35";
    ".gif"   = "00;35";
    ".jpeg"  = "00;35";
    ".jpg"   = "00;35";
    ".mjpeg" = "00;35";
    ".mjpg"  = "00;35";
    ".mng"   = "00;35";
    ".pbm"   = "00;35";
    ".pcx"   = "00;35";
    ".pgm"   = "00;35";
    ".png"   = "00;35";
    ".ppm"   = "00;35";
    ".svg"   = "00;35";
    ".svgz"  = "00;35";
    ".tga"   = "00;35";
    ".tif"   = "00;35";
    ".tiff"  = "00;35";
    ".webp"  = "00;35";
    ".xbm"   = "00;35";
    ".xpm"   = "00;35";
  };
}
