{
  config,
  flake-parts-lib,
  inputs,
  lib,
  my,
  ...
}:

let

  inherit (builtins)
    mapAttrs
    attrValues
  ;

  inherit (flake-parts-lib)
    mkDeferredModuleType
  ;

  inherit (lib)
    concatLists
    filterAttrs
    mapAttrs'
    mkIf
    mkMerge
    mkOption
    nameValuePair
    types
  ;

  inherit (types)
    attrsOf
    submodule
  ;

in

{
  options = {
    hosts = mkOption {
      type = attrsOf (submodule ({ config, name, pairedPkgs, ... }: {
        options = {
          type = mkOption {
            type = types.enum [ "nixos" ];
          };
          nixos.specialArgs = mkOption {
            type = attrsOf types.raw;
            default = {};
          };
          nixos.cfg = mkOption {
            type = mkDeferredModuleType {};
            default = {};
            description = "Host-specific nixos configuration settings.";
            apply = modules: config.nixpkgs.src.lib.nixosSystem {
              # FIXME: Changes generation hash, but I do want it after comparison is no longer needed:
              # prefix = [ "hosts" name "nixos" "cfg" ];
              inherit (config.nixos) specialArgs;
              inherit modules;
            };
          };
          users = mkOption {
            type = attrsOf (submodule {
              options.nixos.cfg = mkOption {
                type = mkDeferredModuleType {};
                default = {};
                description = "User-specific nixos configuration settings.";
              };
            });
          };
        };
        config = mkMerge [
          {
            nixos.cfg.imports = concatLists (map (user: user.nixos.cfg) (attrValues config.users));
            nixos.cfg.networking.hostName = name;
            nixos.specialArgs = {
              inherit inputs;
              nixpkgs = config.nixpkgs.src;
            };
          }
          (mkIf (config.nixpkgs.instantiation == "internal") {
            nixpkgs.system = config.nixos.cfg.config.nixpkgs.hostPlatform.system;
            nixos.cfg.nixpkgs = lib.mkDefault { inherit (my.nixpkgs) config overlays; };
          })
          (mkIf (config.nixpkgs.instantiation == "external") {
            nixos.cfg.imports = [ config.nixpkgs.src.nixosModules.readOnlyPkgs ];
            nixos.cfg.nixpkgs.pkgs = pairedPkgs.pkgs;
          })
        ];
      }));
    };
  };

  config = {
    flake.nixosConfigurations = mapAttrs (name: host: host.nixos.cfg) (filterAttrs (name: host: host.type == "nixos") config.hosts);
    perSystem = { system, ... }: {
      nixpkgs = mapAttrs' (name: host: nameValuePair host.nixpkgs.name {
        src = host.nixpkgs.src;
        args = { inherit (host.nixos.cfg.config.nixpkgs) config overlays; };
        pkgs = host.nixos.cfg.pkgs;
      }) (filterAttrs (name: host: host.type == "nixos" && host.nixpkgs.system == system && host.nixpkgs.instantiation == "internal") config.hosts);
    };
  };
}
