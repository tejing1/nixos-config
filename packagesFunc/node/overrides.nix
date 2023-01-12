{ pkgs, nodejs }:
let
  inherit (pkgs) lib;
in
final: prev:
{
  hred = prev.hred.override (oldAttrs: {
    nativeBuildInputs = with pkgs; [ pkg-config ];
    buildInputs = with pkgs; [ pixman cairo pango ];
    meta = oldAttrs.meta // {
      description = "A command-line tool to extract data from HTML";
      license = lib.licenses.mit;
      homepage = "https://github.com/danburzo/hred";
    };
  });
}
