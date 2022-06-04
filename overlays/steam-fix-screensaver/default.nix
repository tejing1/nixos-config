final: prev:
let
  inherit (builtins) concatStringsSep attrValues mapAttrs;
  inherit (final) stdenv stdenv_32bit runCommandWith runCommandLocal makeWrapper;

  # These are the strings that ld-linux.so expands $PLATFORM to. It
  # can be difficult to find the correct values.  The only way I know
  # to do so is to run your ld-linux.so as a standalone executable and
  # check the help output like so:

  # $(ldd "$(command which ls)" | egrep -o '/nix/store/[a-z0-9]+-glibc-[^/]+/lib/ld-linux[^ ]+') --help |
  # grep AT_PLATFORM | egrep -o '^ *[^ ]+' | egrep -o '[^ ]+'

  # replace ls with a 32-bit executable to get the string for 32-bit
  # ld-linux.so

  # This would all be much simpler if $LIB expanded to different
  # strings in 32-bit and 64-bit modes on nixos, like it does on other
  # distros.
  platforms = {
    haswell = 64;
    i686 = 32;
  };

  preloadLibFor = bits: assert bits == 64 || bits == 32;
    runCommandWith {
      stdenv = if bits == 64 then stdenv else stdenv_32bit;
      runLocal = false;
      name = "filter_SDL_DisableScreenSaver.${toString bits}bit.so";
      derivationArgs = {};
    } "gcc -shared -fPIC -ldl -m${toString bits} -o $out ${./filter_SDL_DisableScreenSaver.c}";

  preloadLibs = runCommandLocal "filter_SDL_DisableScreenSaver" {} (concatStringsSep "\n" (attrValues (mapAttrs (platform: bits: ''
    mkdir -p $out/${platform}
    ln -s ${preloadLibFor bits} $out/${platform}/filter_SDL_DisableScreenSaver.so
  '') platforms)));
in
{
  steam = prev.steam.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ makeWrapper ];
    buildCommand = (old.buildCommand or "") + ''
      steamBin="$(readlink $out/bin/steam)"
      rm $out/bin/steam
      makeWrapper $steamBin $out/bin/steam --prefix LD_PRELOAD : ${preloadLibs}/\$PLATFORM/filter_SDL_DisableScreenSaver.so
    '';
  });
}
