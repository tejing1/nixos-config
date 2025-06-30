{ inputs, ... }:

{
  imports = inputs.self.lib.listImportablePathsExcept ./. [ "default" ];
}
