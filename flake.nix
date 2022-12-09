{
  inputs.nixpkgs.url      = "github:NixOS/nixpkgs/nixos-22.11";
  inputs.home-manager.url = "github:nix-community/home-manager/release-22.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs: (import ./lib inputs).importAllExceptWithArg ./. [ "flake.nix" ] inputs;
}
