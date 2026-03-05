{ inputs, ... }:

{
  my.flake.inputs = {
    vieb-nix.url = "github:tejing1/vieb-nix";
    vieb-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  perPkgs = { pkgs, ... }: {
    my.pkgs = {
      inherit (inputs.vieb-nix.packagesFunc pkgs) vieb;
    };
  };
}
