{ buildFHSUserEnv, coreutils, fetchzip, gnused, stdenv, writeShellScript }:

let
  version = "0.95.1a-RC6";
  sha256 = "sha256-+0zGJHM+SMonx3sytCQNQA/QBgzdPMEfQvOjrCDSOs8=";

  modify_starsector_sh = builtins.toFile "modify_starsector_sh.sed" ''
    # Exec so we don't have a useless process lying around
    s:./jre_linux/bin/java:exec ./jre_linux/bin/java:

    # Setting -Djava.util.prefs.userRoot="$configdir" makes java store "User Prefs" in $configdir/.java instead of ~/.java
    s:./jre_linux/bin/java:./jre_linux/bin/java -Djava.util.prefs.userRoot="$configdir":

    # Redirect saved game files
    s:-Dcom.fs.starfarer.settings.paths.saves=./saves:-Dcom.fs.starfarer.settings.paths.saves="$configdir"/saves:

    # Redirect screenshots
    s:-Dcom.fs.starfarer.settings.paths.screenshots=./screenshots:-Dcom.fs.starfarer.settings.paths.screenshots="$configdir"/sceenshots:

    # Redirect logs
    s:-Dcom.fs.starfarer.settings.paths.logs=.:-Dcom.fs.starfarer.settings.paths.logs="$configdir":

    # Set where to look for mods
    s:-Dcom.fs.starfarer.settings.paths.mods=./mods:-Dcom.fs.starfarer.settings.paths.mods="$modsdir":
  '';
in

buildFHSUserEnv {
  name = "starsector";

  targetPkgs = pkgs: builtins.attrValues {

    inherit (pkgs)
      alsa-lib
      gtk2
      libGL
      libxslt
    ;

    inherit (pkgs.xorg)
      libX11
      libXext
      libXrandr
      libXrender
      libXcursor
      libXi
      libXxf86vm
      libXtst
    ;

  };

  runScript = writeShellScript "starsector" ''
    # Change dir to unzipped game dir
    cd ${fetchzip {
      url = "https://s3.amazonaws.com/fractalsoftworks/starsector/starsector_linux-${version}.zip";
      inherit sha256;
    }}

    # Determine state dir and mods dir
    configdir="''${STARSECTOR_CONFIG_DIR:-"''${XDG_CONFIG_HOME:-"$HOME"/.config}"/starsector}"
    modsdir="''${STARSECTOR_MODS_DIR:-"$configdir"/mods}"
    unset STARSECTOR_CONFIG_DIR STARSECTOR_MODS_DIR

    # Initialize state dir
    ${coreutils}/bin/mkdir -p "$configdir"/{saves,screenshots}

    # Modify start script
    toEval="$(${gnused}/bin/sed -f ${modify_starsector_sh} ./starsector.sh)"

    # Run start script (will exec)
    eval "$toEval"
  '';
}
