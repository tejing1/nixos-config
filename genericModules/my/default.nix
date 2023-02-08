{ inputs, ... }:

{
  imports = inputs.self.lib.listImportablePathsExcept ./. [ "default.nix" ];
}
