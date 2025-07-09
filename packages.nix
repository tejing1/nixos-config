{ self, ... }:

{
  perSystem = { pkgs, ... }: {
    packages = self.packagesFunc pkgs;
  };
}
