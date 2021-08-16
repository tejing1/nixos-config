{ lib, my, options, ... }@args:
let
  inherit (lib) mkOption types hasAttrByPath;
in

{
  options.my.context = {
    type = mkOption {
      type = types.strMatching "nixos|home-manager";
      description = "Which kind of module are we?";
    };
    variant = mkOption (
      if my.context.type == "home-manager" then
        {
          type = types.strMatching "standalone|nixos";
          description = "How home-manager is being used";
        }
      else
        {
          type = types.strMatching "";
          description = "Further information on context. Not used when my.context.type is \"${my.context.type}\"";
        }
    );
  };
  config.my.context =
    if hasAttrByPath [ "system" "stateVersion" ] options then
      {
        type = "nixos";
        variant = "";
      }
    else if hasAttrByPath [ "home" "stateVersion" ] options then
      {
        type = "home-manager";
        variant =
          if args ? nixosConfig then
            "nixos"
          else
            "standalone"
        ;
      }
    else
      throw "Could not determine my.context.type"
  ;
}
