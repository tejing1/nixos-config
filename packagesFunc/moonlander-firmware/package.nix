{
  lib,
  callPackage,
  stdenv,
  qmk,
  python3Packages,
  writeText,
}:
let
  inherit (builtins) readFile elemAt;
  inherit (lib.strings) match;
  inherit (lib) concatStringsSep;

  vinfo = match "(.*\n)?#define FIRMWARE_VERSION u8\"([A-Za-z0-9]+)/([A-Za-z0-9]+)\"(\n.*)?" (readFile keymap/config.h);
  inherit (callPackage _sources/generated.nix {}) qmk_firmware;

  kb = "moonlander";
  km = elemAt vinfo 1;
  version = elemAt vinfo 2;
in stdenv.mkDerivation (finalAttrs: {
  name = "${kb}_${km}-${version}.${qmk_firmware.version}.bin";

  inherit (qmk_firmware) src;
  postPatch = ''
    # Clean up some issues with the old python code in qmk_firmware
    sed -i -e 's/cli._subcommand.__name__/cli.subcommand_name/g' lib/python/qmk/decorators.py
    sed -i -e '77,79 s/\\e/\\\\e/g; 77,78 s/\\\[/\\\\[/g; 77,78 s/\\\]/\\\\]/g' lib/python/qmk/cli/multibuild.py
    sed -i -e '33 s/\\B/\\\\B/g' lib/python/qmk/cli/bux.py

    # Install my keymap's files where qmk expects them
    cp -r ${./keymap} keyboards/${kb}/keymaps/${km}
  '';

  nativeBuildInputs = [
    # qmk now includes the necessary compilers and whatnot in its propagatedBuildInputs
    (qmk.overridePythonAttrs (old: {
      propagatedBuildInputs = old.propagatedBuildInputs or [] ++ [
        # Required by qmk_firmware <= 0.26.9.
        # Change to just use plain qmk once NixOS/nixpkgs#412129 is in my nixpkgs commit.
        python3Packages.appdirs
      ];
    }))
  ];

  # Prevent `qmk compile` from trying to read things from .git that aren't there.
  env.SKIP_GIT = 1;

  buildPhase = "qmk compile -kb ${kb} -km ${km}";

  installPhase = "install -m 444 ${kb}_${km}.bin $out";

  dontFixup = true;

  passthru.buildTools = writeText "moonlander-firmare-buildTools" (concatStringsSep "\n" (finalAttrs.nativeBuildInputs ++ [ finalAttrs.src ]));
})
