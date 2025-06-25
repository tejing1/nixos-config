{ config, lib, my, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkMerge mkBefore;
in
{
  options.my.customize.shell = mkEnableOption "shell customization";
  config = {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        htop
        killall
        mkpasswd
        tmux
        unzip
        lshw
        pciutils
        wget
        lastpass-cli
        ranger
        nix-prefetch-github
        jq jc jo gron yj yq pup # json/toml/yaml/hcl/xml/html handling
        bc # also includes dc
        moreutils # sponge & more
        man-pages # linux kernel apis and other development man pages
        faketty
      ;
      inherit (my.pkgs)
        hred
      ;
      nom = pkgs.nix-output-monitor.overrideAttrs (old: { postPatch = old.postPatch or "" + ''
        sed -ie ${lib.escapeShellArg ''
          s/↓/\\xf072e/
          s/↑/\\xf0737/
          s/⏱/\\xf520/
          s/⏵/\\xf04b/
          s/✔/\\xf00c/
          s/⏸/\\xf04d/
          s/⚠/\\xf071/
          s/∅/\\xf1da/
          s/∑/\\xf04a0/
          ''} lib/NOM/Print.hs
      ''; });
    };
    programs.fish.enable = true;
    programs.dircolors.enableFishIntegration = true;
    programs.starship.enableFishIntegration = true;
    programs.fish.shellInit = ''
      set fish_greeting '''
    '';
    programs.fish.functions = {
      update_hm_env = ''
      set -e __HM_SESS_VARS_SOURCED
      set --prepend fish_function_path ${
        if pkgs ? fishPlugins && pkgs.fishPlugins ? foreign-env then
          "${pkgs.fishPlugins.foreign-env}/share/fish/vendor_functions.d"
        else
          "${pkgs.fish-foreign-env}/share/fish-foreign-env/functions"
      }
      fenv source ${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh > /dev/null
      set -e fish_function_path[1]
      '';
    };
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
      nixos-rebuild = "nixos-rebuild --fast --use-remote-sudo";
      # colorize grep output
      grep = "grep --color=auto";
    };

    programs.bash.enable = true;
    programs.dircolors.enableBashIntegration = true;
    programs.starship.enableBashIntegration = true;
    programs.bash.shellAliases = config.programs.fish.shellAliases;

    programs.zsh.enable = true;
    programs.dircolors.enableZshIntegration = true;
    programs.starship.enableZshIntegration = false;
    programs.zsh.shellAliases = config.programs.fish.shellAliases;
    programs.zsh.autosuggestion.enable = true;
    programs.zsh.defaultKeymap = "emacs";
    programs.zsh.initContent = mkMerge [
      (mkBefore ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      ''
        setopt extended_glob
        setopt interactivecomments
        setopt rmstarsilent
        unset RPS1
        bindkey "^I" complete-word
        bindkey "^[l" reset-prompt
        bindkey "$(echoti kend)" end-of-line
        bindkey "$(echoti khome)" beginning-of-line
        bindkey "$(echoti kdch1)" delete-char
        bindkey '^[Oc' forward-word
        bindkey '^[Od' backward-word
        bindkey '^H' backward-kill-word

        . ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${./p10k.zsh}
        . ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

        # Display $1 in terminal title.
        function set-term-title() {
          emulate -L zsh
          if [[ -t 1 ]]; then
            print -rn -- $'\e]0;'${"$"}{(V)1}$'\a'
          elif [[ -w $TTY ]]; then
            print -rn -- $'\e]0;'${"$"}{(V)1}$'\a' >$TTY
          fi
        }

        # When a command is running, display it in the terminal title.
        function set-term-title-preexec() {
          if (( P9K_SSH )); then
            set-term-title ''${(V%):-"%n@%m: "}$1
          else
            set-term-title $1
          fi
        }

        # When no command is running, display the current directory in the terminal title.
        function set-term-title-precmd() {
          if (( P9K_SSH )); then
            set-term-title ''${(V%):-"%n@%m: %~"}
          else
            set-term-title ''${(V%):-"%~"}
          fi
        }

        autoload -Uz add-zsh-hook
        add-zsh-hook preexec set-term-title-preexec
        add-zsh-hook precmd set-term-title-precmd
      ''
    ];

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
        zsh_indicator = "[ZSH](bright-white) ";
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
  };
}
