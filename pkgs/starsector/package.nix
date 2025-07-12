{
  lib,
  fetchzip,
  libGL,
  makeWrapper,
  coreutils,
  openal,
  openjdk,
  stdenv,
  xorg,
  copyDesktopItems,
  makeDesktopItem,
  writeScript,
}:

let
  inherit (builtins) fromJSON readFile;
  inherit (lib) escapeShellArg;

  inherit (fromJSON (readFile ./pin.json)) version url hash;

  # These strings are parsed at game start time
  configDirBash = ''"''${STARSECTOR_CONFIG_DIR:-"''${XDG_CONFIG_HOME:-"$HOME"/.config}"/starsector}"'';
  modsDirBash = ''''${STARSECTOR_MODS_DIR:-${configDirBash}/mods}'';
in

stdenv.mkDerivation (finalAttrs: {
  pname = "starsector";
  inherit version;

  src = fetchzip { inherit url hash; };

  postPatch = ''
    substituteInPlace starsector.sh \
      --replace-fail "./jre_linux/bin/java"\
          "exec ${openjdk}/bin/java -Djava.util.prefs.userRoot="${escapeShellArg configDirBash} \
      --replace-fail "./native/linux" \
          "$out/share/starsector/native/linux" \
      --replace-fail "./compiler_directives.txt" \
          "$out/share/starsector/compiler_directives.txt" \
      --replace-fail -Dcom.fs.starfarer.settings.paths.saves=./saves \
                     -Dcom.fs.starfarer.settings.paths.saves=${escapeShellArg configDirBash}/saves \
      --replace-fail -Dcom.fs.starfarer.settings.paths.screenshots=./screenshots \
                     -Dcom.fs.starfarer.settings.paths.screenshots=${escapeShellArg configDirBash}/screenshots \
      --replace-fail -Dcom.fs.starfarer.settings.paths.logs=. \
                     -Dcom.fs.starfarer.settings.paths.logs=${escapeShellArg configDirBash} \
      --replace-fail -Dcom.fs.starfarer.settings.paths.mods=./mods \
                     -Dcom.fs.starfarer.settings.paths.mods=${escapeShellArg modsDirBash}
  '';

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];
  buildInputs = [
    xorg.libXxf86vm
    openal
    libGL
  ];

  dontBuild = true;

  desktopItems = [
    (makeDesktopItem {
      name = "starsector";
      exec = "starsector";
      icon = "starsector";
      comment = finalAttrs.meta.description;
      genericName = "starsector";
      desktopName = "Starsector";
      categories = [ "Game" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/starsector
    rm -r jre_linux # remove bundled jre7
    rm starfarer.api.zip
    cp -r ./* $out/share/starsector

    mkdir -p $out/share/icons/hicolor/64x64/apps
    ln -s $out/share/starsector/graphics/ui/s_icon64.png \
      $out/share/icons/hicolor/64x64/apps/starsector.png

    makeWrapper $out/share/starsector/starsector.sh $out/bin/starsector \
      --prefix PATH : ${
        lib.makeBinPath [
          openjdk
          xorg.xrandr
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.buildInputs} \
      --run '${coreutils}/bin/mkdir -p '${escapeShellArg configDirBash}'/{saves,screenshots}' \
      --chdir "$out/share/starsector"

    runHook postInstall
  '';

  meta = {
    description = "An open-world single-player space-combat, roleplaying, exploration, and economic game";
    longDescription = "Starsector (formerly “Starfarer”) is an in-development open-world single-player space-combat, roleplaying, exploration, and economic game. You take the role of a space captain seeking fortune and glory however you choose.";
    homepage = "https://fractalsoftworks.com";
    downloadPage = "https://fractalsoftworks.com/preorder";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
})
