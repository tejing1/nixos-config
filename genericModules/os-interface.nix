{ config, lib, ... }:
let
  inherit (lib) mkOption types mkMerge isType zipAttrsWith all any mapAttrs filterAttrs isAttrs mapAttrsRecursiveCond mergeOneOption mergeDefinitions;
  inherit (types) mkOptionType;
  zipAttrsRecursiveCondWith' =
    prefix: cond: f:
    zipAttrsWith (
      name: vals:
      let
        path = prefix ++ [ name ];
      in
      if all cond vals then
        zipAttrsRecursiveCondWith' path cond f vals
      else if any cond vals then
        throw "zipAttrsRecursiveCondWith cannot merge leaves with non-leaves"
      else
        f path vals
    );
  zipAttrsRecursiveCondWith = zipAttrsRecursiveCondWith' [];
  filterAttrsRecursiveCond =
    recurseCond: filterCond: set:
    mapAttrs (n: v: if recurseCond v then filterAttrsRecursiveCond recurseCond filterCond v else v)
      (filterAttrs (n: v: recurseCond v || filterCond v) set);
  osInterfaceOption = mkOptionType {
    name = "osInterfaceOption";
    check = isType "os-interface-option-type";
    merge = mergeOneOption;
  };
  mkOsInterfaceOption =
    {
      # an attribute set suitable to be passed to mkOption
      option,

      # a boolean, determining whether the option is merged across users (or per-user)
      merged ? true,

      # if merged == true, a function which takes a list of user requests and returns the system's response
      # if merged == false, a function which takes a list of user requests and returns a list of the system's responses
      merge ? if merged then mkMerge else (x: x)
    }:
    {
      _type = "os-interface-option-type";
      inherit option merged merge;
    };
  osInterfaceOptions = mkOptionType rec {
    name = "osInterfaceOptions";
    description = "deep attribute set of OS Interface Options";
    check = isAttrs;
    merge = loc: defs:
      let
        formattedDefs = map (def: mapAttrsRecursiveCond (x: ! isType "os-interface-option-type" x) (n: v: { _type = "temp-type"; inherit (def) file; value = v; }) def.value) defs;
        mergedDefs = zipAttrsRecursiveCondWith (x: ! isType "temp-type" x) (path: defs:
          (mergeDefinitions (loc ++ path) osInterfaceOption defs).optionalValue // { _type = "temp-type"; }
        ) formattedDefs;
        filteredDefs = filterAttrsRecursiveCond (v: ! isType "temp-type" v) (v: v ? value) mergedDefs;
        result = mapAttrsRecursiveCond (x: ! isType "temp-type" x) (n: v: v.value) filteredDefs;
      in
        result;
    emptyValue = { value = {}; };
    getSubOptions = prefix: osInterfaceOption.getSubOptions (prefix ++ ["<attribute-path>"]);
#    getSubModules = osInterfaceOption.getSubModules;
    functor = (types.defaultFunctor name) // { type = osInterfaceOptions; wrapped = osInterfaceOption; };
    nestedTypes.optionType = osInterfaceOption;
  };
in
{
  options.osoptions = mkOption {
    type = osInterfaceOptions;
    default = {};
  };
  config.osoptions = mkMerge [
    {test1 = mkOsInterfaceOption { option = { type = types.bool; default = false; }; merge = any (x: x); };}
    {t.e.s.t.a = mkOsInterfaceOption { option = { type = types.bool; default = false; }; merge = any (x: x); };}
    {t.e.s.t.b = mkOsInterfaceOption { option = { type = types.bool; default = false; }; merge = any (x: x); };}
  ];
  options.os = mapAttrsRecursiveCond (x: isAttrs x && ! isType "os-interface-option-type" x) (_: opt: mkOption opt.option) config.osoptions;
  config.os.test1 = true;
  config.os.t.e.s.t.a = true;
}
