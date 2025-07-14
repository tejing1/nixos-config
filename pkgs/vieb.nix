{ inputs, ... }:

{
  perPkgs = { pkgs, ... }: {
    my.pkgs = {
      inherit (inputs.vieb-nix.packagesFunc pkgs) vieb;
    };
  };
}
