{ lib, callPackage, stdenv, qmk, gcc-arm-embedded, pkgsCross, avrdude, dfu-programmer, dfu-util, writeText }:
let
  inherit (builtins) readFile elemAt;
  inherit (lib.strings) match;

  vinfo = match "(.*\n)?#define FIRMWARE_VERSION u8\"([A-Za-z0-9]+)/([A-Za-z0-9]+)\"(\n.*)?" (readFile keymap/config.h);
  inherit (callPackage _sources/generated.nix {}) qmk_firmware;

  kb = "moonlander";
  km = elemAt vinfo 1;
  version = elemAt vinfo 2;
in stdenv.mkDerivation (this: {
  name = "${kb}_${km}-${version}.${qmk_firmware.version}.bin";

  inherit (qmk_firmware) src;
  postPatch = "cp -r ${./keymap} keyboards/${kb}/keymaps/${km}";

  buildInputs = [ qmk gcc-arm-embedded pkgsCross.avr.buildPackages.gcc8 avrdude dfu-programmer dfu-util ];

  configurePhase = "qmk setup -y";
  buildPhase = "SKIP_GIT=1 qmk compile -kb ${kb} -km ${km}";
  installPhase = "cp --no-preserve=mode ${kb}_${km}.bin $out";
  dontFixup = true;
  passthru.buildTools = writeText "moonlander-firmare-buildTools" (lib.concatStringsSep "\n" (this.buildInputs ++ [ this.src ]));
})
