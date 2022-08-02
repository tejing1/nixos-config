{ lib, my, pkgs, ... }:

let
  inherit (my.lib) importSecret;
in
{
  # Enable my sfeed module
  my.sfeed.enable = true;

  # Update every 30 mins
  my.sfeed.update = "*:00,30:00";

  # Pass useful args through to submodule config
  my.sfeed.rc._module.args = { inherit pkgs my; };
  my.sfeed.rc.imports = [

    # Public config, including some useful site-specific code
    ./rc.public.nix

    # Private config, including most of the actual feeds.<name> values
    (importSecret {} ./rc.secret.nix)

  ];
}
