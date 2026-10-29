{
  flake-parts-lib,
  inputs,
  lib,
  my,
  ...
}:

let

  inherit (flake-parts-lib)
    mkDeferredModuleType
  ;

  inherit (lib)
    filterAttrs
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    types
  ;
  inherit (types)
    attrsOf
    enum
    submodule
  ;

in

{
  options = {
    hosts = mkOption {
      type = attrsOf (submodule ({ config, ... }: {
        options = {
          hm.module = mkEnableOption "home-manager module";
          hm.src = mkOption {
            type = my.lib.types.flakeInput;
          };
          hm.cfg = mkOption {
            type = mkDeferredModuleType {};
            default = {};
            description = "Host-specific home-manger configuration settings, applying to all users on this host.";
          };
          users = mkOption {
            type = attrsOf (submodule ({ ... }: {
              options.type = mkOption {
                type = enum [ "hm-module" ];
              };
              options.hm.cfg = mkOption {
                type = mkDeferredModuleType {
                  imports = config.hm.cfg;
                };
                default = {};
                description = "Home-manager configuration settings.";
              };
            }));
          };
        };
        config = mkIf config.hm.module {
          nixos.specialArgs.home-manager = config.hm.src;
          nixos.cfg = {
            imports = [ config.hm.src.nixosModules.home-manager ];

            # Use /etc/profiles instead of ~/.nix-profile
            # In particular, this allows 'nixos-rebuild build-vm' and home-manager to work together
            home-manager.useUserPackages = true;

            # Use the system's nixpkgs instance
            home-manager.useGlobalPkgs = true;

            # Pass specialArgs through to home-manager
            home-manager.extraSpecialArgs = {
              inherit inputs;
              nixpkgs = config.nixpkgs.src;
              home-manager = config.hm.src;
            };

            # Import my basic modules for all users
            home-manager.sharedModules = [ inputs.self.homeModules.my ];

            home-manager.users = mapAttrs (n: v: { imports = v.hm.cfg; }) (filterAttrs (n: v: v.type == "hm-module") config.users);
          };
        };
      }));
    };
  };
}
