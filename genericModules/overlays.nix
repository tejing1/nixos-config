{ inputs, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.overlays = mkOption {
    type = types.unspecified;
    description = "Overlays from self.overlays";
    visible = false;
    readOnly = true;
  };
  config.my.overlays = inputs.self.overlays;
}
