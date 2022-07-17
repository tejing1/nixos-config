{ buildFHSUserEnv, fetchurl, stdenv, unzip, writeShellScript }:

let
  gamedir = stdenv.mkDerivation (self: {
    pname = "starsector";
    version = "0.95.1a-RC6";
    sha256 = "sha256-PaiL1RmKHDWrVX/xGXPE5vokPBOTah+vGjhn14/+/ZM=";

    src = fetchurl {
      url = "https://s3.amazonaws.com/fractalsoftworks/starsector/starsector_linux-${self.version}.zip";
      inherit (self) sha256;
    };

    nativeBuildInputs = [ unzip ];

    installPhase = ''
      mkdir -p $out
      cp -a * $out/
      substituteInPlace $out/starsector.sh \
        --replace ./jre_linux/bin/java 'exec ./jre_linux/bin/java -Djava.util.prefs.userRoot="$configdir"' \
        --replace -Dcom.fs.starfarer.settings.paths.saves=./saves             '-Dcom.fs.starfarer.settings.paths.saves="$configdir"/saves' \
        --replace -Dcom.fs.starfarer.settings.paths.screenshots=./screenshots '-Dcom.fs.starfarer.settings.paths.screenshots="$configdir"/sceenshots' \
        --replace -Dcom.fs.starfarer.settings.paths.logs=.                    '-Dcom.fs.starfarer.settings.paths.logs="$configdir"' \
        --replace -Dcom.fs.starfarer.settings.paths.mods=./mods               '-Dcom.fs.starfarer.settings.paths.mods="$modsdir"'
    '';
  });
in

# TODO: redirect java user prefs away from ~/.java

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
    cd ${gamedir}
    configdir="''${STARSECTOR_CONFIG_DIR:-$HOME/.config/starsector}"
    modsdir="''${STARSECTOR_MODS_DIR:-./mods}"
    unset STARSECTOR_CONFIG_DIR STARSECTOR_MODS_DIR
    mkdir -p "$configdir"/{saves,screenshots}
    source ./starsector.sh
  '';
}
