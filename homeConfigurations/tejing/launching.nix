{ lib, my, pkgs, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.launch = mkOption {
    type = types.unspecified;
    description = "My launcher script";
    visible = false;
    readOnly = true;
  };

  config = {
    my.launch.pkg = pkgs.writeShellScriptBin "mylaunch" ''
      if [ "$#" -lt 3 ]; then
          echo "Usage: $0 [slice] [name] [command] [args...]"
          exit 1
      fi
      slice="$1"
      name="$2"
      cmd="$3"
      shift 3

      exec ${pkgs.systemd}/bin/systemd-run --user --no-ask-password --quiet --same-dir --collect --scope \
        --slice="$slice" \
        --unit="$name"-"$(${pkgs.coreutils}/bin/date '+%Y-%m-%d-%H:%M:%S.%N')"-pid-"$$" \
        ${pkgs.bash}/bin/bash -c "exec $(printf "%q" "$cmd") \"\$@\"" -- "$@"
    '';
    my.launch.outPath = "${my.launch.pkg}/bin/mylaunch";
    my.launch.term.pkg = let
      env = "${pkgs.coreutils}/bin/env";
      urxvtc = "${pkgs.rxvt-unicode}/bin/urxvtc";
      urxvt = "${pkgs.rxvt-unicode}/bin/urxvt";
    in pkgs.writeShellScriptBin "mylaunchterm" ''
      name="$2"

      ${env} SHLVL= ${urxvtc} -name "$name" -title "$name" -e ${my.launch} "$@"
      if [ "$?" -eq 2 ]; then
          exec ${env} SHLVL= ${urxvt} -name "$name" -title "$name" -e ${my.launch} "$@"
      fi
    '';
    my.launch.term.outPath = "${my.launch.term.pkg}/bin/mylaunchterm";
  };
}
