{
  config,
  flake-parts-lib,
  lib,
  ...
}:

let

  inherit (flake-parts-lib)
    mkDeferredModuleType
  ;

  inherit (lib)
    attrNames
    defaultFunctor
    filter
    isAttrs
    isFunction
    last
    mkOption
    mkOptionType
    noCheckForDocsModule
    optionalAttrs
    optionDescriptionPhrase
    path
    types
  ;

  inherit (types)
    attrsOf
    enum
    submodule
  ;

  # Copied from <nixpkgs/lib/types.nix> and modified to pass `name` through specialArgs so I can use it to calculate `imports`
  inherit (lib.options)
    showDefs
  ;
  checkDefsForError =
    check: loc: defs:
    let
      invalidDefs = filter (def: !check def.value) defs;
    in
    if invalidDefs != [ ] then { message = "Definition values: ${showDefs invalidDefs}"; } else null;

  mySubmoduleWith =
    {
      modules,
      specialArgs ? { },
      shorthandOnlyDefinesConfig ? false,
      description ? null,
      class ? null,
    }@attrs:
    let
      inherit (lib.modules) evalModules;

      allModules =
        defs:
        map (
          { value, file }:
          if isAttrs value && shorthandOnlyDefinesConfig then
            {
              _file = file;
              config = value;
            }
          else
            {
              _file = file;
              imports = [ value ];
            }
        ) defs;

      base = evalModules {
        inherit class modules;
        specialArgs = {
          name = "‹name›";
        } // specialArgs;
      };

      freeformType = base._module.freeformType;

      name = "submodule";

      check = {
        __functor = _self: x: isAttrs x || isFunction x || path.check x;
        isV2MergeCoherent = true;
      };
    in
    mkOptionType {
      inherit name;
      description =
        if description != null then
          description
        else
          let
            docsEval = base.extendModules { modules = [ noCheckForDocsModule ]; };
          in
          if docsEval._module.freeformType ? description then
            "open ${name} of ${
              optionDescriptionPhrase (
                class: class == "noun" || class == "composite"
              ) docsEval._module.freeformType
            }"
          else
            name;
      inherit check;
      merge = {
        __functor =
          self: loc: defs:
          (self.v2 { inherit loc defs; }).value;
        v2 =
          { loc, defs }:
          let
            configuration = base.extendModules {
              specialArgs = { name = last loc; };
              modules = allModules defs;
              prefix = loc;
            };
          in
          {
            headError = checkDefsForError check loc defs;
            value = configuration.config;
            valueMeta = { inherit configuration; };
          };
      };
      emptyValue = {
        value = { };
      };
      getSubOptions =
        prefix:
        let
          docsEval = (
            base.extendModules {
              inherit prefix;
              modules = [ noCheckForDocsModule ];
            }
          );
          # Intentionally shadow the freeformType from the possibly *checked*
          # configuration. See `noCheckForDocsModule` comment.
          inherit (docsEval._module) freeformType;
        in
        docsEval.options
        // optionalAttrs (freeformType != null) {
          # Expose the sub options of the freeform type. Note that the option
          # discovery doesn't care about the attribute name used here, so this
          # is just to avoid conflicts with potential options from the submodule
          _freeformOptions = freeformType.getSubOptions prefix;
        };
      getSubModules = modules;
      substSubModules =
        m:
        mySubmoduleWith (
          attrs
          // {
            modules = m;
          }
        );
      nestedTypes = lib.optionalAttrs (freeformType != null) {
        freeformType = freeformType;
      };
      functor = defaultFunctor name // {
        type = mySubmoduleWith;
        payload = {
          inherit
            modules
            class
            specialArgs
            shorthandOnlyDefinesConfig
            description
            ;
        };
        binOp = lhs: rhs: {
          class =
            # `or null` was added for backwards compatibility only. `class` is
            # always set in the current version of the module system.
            if lhs.class or null == null then
              rhs.class or null
            else if rhs.class or null == null then
              lhs.class or null
            else if lhs.class or null == rhs.class then
              lhs.class or null
            else
              throw "A submoduleWith option is declared multiple times with conflicting class values \"${toString lhs.class}\" and \"${toString rhs.class}\".";
          modules = lhs.modules ++ rhs.modules;
          specialArgs =
            let
              intersecting = builtins.intersectAttrs lhs.specialArgs rhs.specialArgs;
            in
            if intersecting == { } then
              lhs.specialArgs // rhs.specialArgs
            else
              throw "A submoduleWith option is declared multiple times with the same specialArgs \"${toString (attrNames intersecting)}\"";
          shorthandOnlyDefinesConfig =
            if lhs.shorthandOnlyDefinesConfig == null then
              rhs.shorthandOnlyDefinesConfig
            else if rhs.shorthandOnlyDefinesConfig == null then
              lhs.shorthandOnlyDefinesConfig
            else if lhs.shorthandOnlyDefinesConfig == rhs.shorthandOnlyDefinesConfig then
              lhs.shorthandOnlyDefinesConfig
            else
              throw "A submoduleWith option is declared multiple times with conflicting shorthandOnlyDefinesConfig values";
          description =
            if lhs.description == null then
              rhs.description
            else if rhs.description == null then
              lhs.description
            else if lhs.description == rhs.description then
              lhs.description
            else
              throw "A submoduleWith option is declared multiple times with conflicting descriptions";
        };
      };
    };
  # End copied section

in

{
  options = {
    hosts = mkOption {
      type = attrsOf (submodule {
        options.users = mkOption {
          type = attrsOf (mySubmoduleWith {
            shorthandOnlyDefinesConfig = true;
            modules = [
              ({ name, ... }: {
                imports = config.users.${name} or config.perUser;
                options.type = mkOption {
                  type = enum [];
                };
              })
            ];
          });
          default = {};
        };
      });
    };
    users = mkOption {
      type = attrsOf (mkDeferredModuleType {
        imports = config.perUser;
      });
      default = {};
    };
    perUser = mkOption {
      type = mkDeferredModuleType {};
      default = {};
    };
  };
}
