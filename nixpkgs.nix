{
  inputs,
  ...
}:

{
  config = {
    perSystem = { config, ... }: {
      nixpkgs.stable = {
        source = inputs.nixpkgs;
        arg.config.allowUnfree = true;
      };
      nixpkgs.unstable = {
        source = inputs.nixpkgs-unstable;
        inherit (config.nixpkgs.stable) arg;
      };
      nixpkgs.stable-uncustomized.source = inputs.nixpkgs;
      nixpkgs.unstable-uncustomized.source = inputs.nixpkgs-unstable;
      nixpkgs.default = "stable";
    };
  };
}
