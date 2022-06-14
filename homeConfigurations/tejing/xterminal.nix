{ config, lib, my, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) mkOption types;
in
{
  options.my.term = mkOption {
    type = types.unspecified;
    description = "My preferred terminal emulator";
    visible = false;
    readOnly = true;
  };

  config = {
    my.term.pkg = let
      # unfortunately resholve doesn't understand urxvt's args
      basename = "${pkgs.coreutils}/bin/basename";
      readlink = "${pkgs.coreutils}/bin/readlink";
      which = "${pkgs.which}/bin/which";
      env = "${pkgs.coreutils}/bin/env";
      urxvtc = "${pkgs.rxvt-unicode}/bin/urxvtc";
      urxvt = "${pkgs.rxvt-unicode}/bin/urxvt";
    in pkgs.writeShellScriptBin "myterm" ''
      cd ~/data 2>/dev/null || cd ~ || cd /
      name="$(${basename} "$SHELL")"
      if [ "$(${readlink} -f "$(${which} "$name")")" == "$(${readlink} -f "$SHELL")" ]; then
          cmd="$name"
      elif [ "$(${basename} "$(${readlink} -f "$SHELL")")" == "$name" ]; then
          cmd="$(${readlink} -f "$SHELL")"
      else
          cmd="$SHELL"
      fi
      ${env} SHLVL= ${urxvtc} -name "$name" -title "$name" -e ${my.launch} shells "$name" "$cmd"
      if [ "$?" -eq 2 ]; then
          exec ${env} SHLVL= ${urxvt} -name "$name" -title "$name" -e ${my.launch} shells "$name" "$cmd"
      fi
    '';
    my.term.outPath = "${my.term.pkg}/bin/myterm";
    home.packages = attrValues {
      mylaunchterm = my.launch.term.pkg;
      mylaunch = my.launch.pkg;
      myterm = my.term.pkg;
    };
    programs.urxvt.enable = true;
    programs.urxvt.fonts = [ "xft:DejaVuSansMono Nerd Font Mono:pixelsize=15" ];
    programs.urxvt.scroll.bar.enable = false;
    programs.urxvt.scroll.lines = 0;
    programs.urxvt.iso14755 = false;
    programs.urxvt.extraConfig = {
      background = "rgba:0000/0000/0000/C000";
      foreground = "#00ff00";
      depth = 32;
      internalBorder = 0;
      perl-ext-common = "default,-readline,-searchable-scrollback";
      pointerBlank = true;
    };
    xsession.windowManager.i3.config.keybindings = let
      mod = config.xsession.windowManager.i3.config.modifier;
    in {
      "${mod}+Return" = "exec --no-startup-id ${my.term}";
    };
    xresources.properties = {
      "Xft.antialias" = 1;
      "Xft.rgba" = "rgb";
    };
  };
}
