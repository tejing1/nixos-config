{ inputs, ... }:

{
  my.pkgsFunc = pkgs: {
    inherit (inputs.vieb-nix.packagesFunc pkgs) vieb;
  };
}
