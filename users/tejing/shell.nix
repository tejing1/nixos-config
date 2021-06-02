{ pkgs, ... }:

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
  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = false;
    format = "$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$cmd_duration$jobs$character";

    username = {
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
      format = "[$symbol$branch]($style) ";
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
	    success_symbol = "\\$";
	    error_symbol = "\\$";
    };
  };
}
