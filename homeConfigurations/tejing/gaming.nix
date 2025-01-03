{ config, lib, my, pkgs, ... }:

let
  inherit (builtins) toFile;
  inherit (my.lib) mkShellScript;
in {
  home.packages = builtins.attrValues {
    inherit (pkgs)
      lutris
    ;
    inherit (my.pkgs)
      starsector
    ;
  };

  # prevent compositing performance hit when gaming
  services.picom.settings.unredir-if-possible = true;

  # Use rofi to launch steam games
  xsession.windowManager.i3.config.keybindings = let
    mod = config.xsession.windowManager.i3.config.modifier;
  in {
    "${mod}+g" = "exec --no-startup-id ${mkShellScript "mysteamlaunch" {
      inputs = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.jq
        pkgs.rofi
      ];
      execer = [ "cannot:${pkgs.rofi}/bin/rofi" ];
      fake.external = [ "steam" ]; # Look this up in PATH. May not be the best idea in theory, but it's what I'm doing.
    } ''
      set -euo pipefail

      lastrun_file="$HOME/.cache/mysteamlaunch/lastrun"
      if [ -f "$lastrun_file" ]; then
        selected="$(< "$lastrun_file")"
      fi
      record_choice() {
        mkdir -p -- "$(dirname -- "$lastrun_file")"
        printf "%s\n" "$id" > "$lastrun_file"
      }

      listgames() {
        find ~/.local/share/Steam/steamapps/ /mnt/persist/share/data/tejing/replaceable/steam/local_share_Steam/steamapps/ -maxdepth 1 -type f -name '*.acf' -exec jq -sRrf ${toFile "parseacf.jq" ''
          def convert:
            capture("\\s*(?<key>\"[^\"]*\")\\s+(?<value>\"[^\"]*\"|({(?:\\s*\"[^\"]*\"\\s+(?:\"[^\"]*\"|\\g<-1>))*\\s*}))";"g") |
              (.key,.value) |=
                if startswith("{")
                then ltrimstr("{") | rtrimstr("}") | [convert] | from_entries
                elif startswith("\"")
                then ltrimstr("\"") | rtrimstr("\"")
                else error("Does not appear to be a string or object: \(.)")
                end;
            convert | .value | [ .appid, .name ] | @tsv
        ''} '{}' '+' | sort -k2
      }

      choosegame() {
        rofi -dmenu -i -matching fuzzy -no-custom -display-columns 2 -l 50 -p 'Game to start' ''${selected:+-select "$selected"} | cut -f1
      }

      id="$(listgames | choosegame)" && record_choice && steam "steam://rungameid/$id"
    ''}";
  };

  xsession.windowManager.i3.config.assigns."8" = [{class = "^Steam$";}];
}
