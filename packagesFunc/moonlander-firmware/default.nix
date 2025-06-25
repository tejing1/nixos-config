{
  lib,
  callPackage,
  stdenv,
  git,
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
  postPatch = "cp -r ${./keymap} keyboards/${kb}/keymaps/${km}";

  buildInputs = [
    # qmk seems to barf during `qmk setup` if this isn't available. It
    # still continues anyway, but I'd rather avoid the problem.
    git

    # qmk now includes the necessary compilers and whatnot in its propagatedBuildInputs
    (qmk.overridePythonAttrs (old: {
      propagatedBuildInputs = old.propagatedBuildInputs or [] ++ [
        # Required by qmk_firmware <= 0.26.9. See NixOS/nixpkgs#412129
        python3Packages.appdirs
      ];
    }))
  ];

  configurePhase = "qmk setup -y";
  buildPhase = "SKIP_GIT=1 qmk compile -kb ${kb} -km ${km}";
  installPhase = "cp --no-preserve=mode ${kb}_${km}.bin $out";
  dontFixup = true;
  passthru.buildTools = writeText "moonlander-firmare-buildTools" (concatStringsSep "\n" (finalAttrs.buildInputs ++ [ finalAttrs.src ]));
})
