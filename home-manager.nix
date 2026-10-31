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
    submoduleWith
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
            type = attrsOf (submoduleWith {
              modules = [
                ({ pkgsFrom, pkgs, ... }: {
                  options.type = mkOption {
                    type = enum [ "hm-module" ];
                  };
                  options.hm.cfg = mkOption {
                    type = mkDeferredModuleType ({ my, ... }: {
                      imports = config.hm.cfg;

                      config._module.args.pkgsFrom = pkgsFrom;

                      options.my.isBuildVm = mkOption {
                        type = types.bool;
                        description = "Whether the system being built is part of a nixos-rebuild build-vm or build-vm-with-bootloader";
                        default = false;
                      };
                      options.my.isBuildVmWithBootLoader = mkOption {
                        type = types.bool;
                        description = "Whether the system being built is part of a nixos-rebuild build-vm-with-bootloader";
                        default = false;
                      };

                      # FIXME temporary fix. Use my.using.unstable.pkgs and pkgsFrom.unstable at the use site instead.
                      options.my.pkgsUnstable = mkOption {
                        type = types.unspecified;
                        description = "Packages from self, with dependencies from unstable";
                        visible = false;
                        readOnly = true;
                      };
                      config.my.pkgsUnstable = my.using.unstable.pkgs;
                      config._module.args.pkgsUnstable = pkgsFrom.unstable;
                    });
                    default = {};
                    description = "Home-manager configuration settings.";
                  };
                })
              ];
            });
          };
        };
        config = mkIf config.hm.module {
          nixos.specialArgs.home-manager = config.hm.src;
          nixos.cfg = { my, ... }: {
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

            home-manager.sharedModules = [{
              my.isBuildVm = my.isBuildVm;
              my.isBuildVmWithBootLoader = my.isBuildVmWithBootLoader;
            }];

            home-manager.users = mapAttrs (name: user: lib.mkMerge user.hm.cfg) (filterAttrs (name: user: user.enable && user.type == "hm-module") config.users);
          };
        };
      }));
    };
  };
  config = {
    my.flake.inputs = {
      home-manager.url = "github:nix-community/home-manager/release-${my.nixpkgs.release}";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      home-manager-unstable.url = "github:nix-community/home-manager/master";
      home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
}
