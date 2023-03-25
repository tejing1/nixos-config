{ config, lib, pkgs, ... }:

let
  inherit (builtins) concatStringsSep filter any hasAttr attrValues
    length concatMap isList mapAttrs hasContext
    unsafeDiscardStringContext head listToAttrs;
  inherit (lib) concatMapStringsSep escapeShellArgs escapeShellArg
    optionalString optionalAttrs splitString mapAttrsToList groupBy'
    nameValuePair removeSuffix unique filterAttrs makeBinPath
    mkEnableOption mkOption mkIf;
  inherit (lib.types) attrsOf submodule str ints listOf package nullOr submoduleWith;
  inherit (pkgs) resholve;

  # Changing these 2 lines will safely relocate this module's options
  cfg = config.my.sfeed;
  putopt = opt: { my.sfeed = opt; };

  # All functions that can be overridden in sfeedrc
  overrideableFuncs = [
    "fetch"
    "convertencoding"
    "parse"
    "filter"
    "merge"
    "order"
  ];

  # prepend a string onto each line of another string
  indentString = ind: str: ind + concatStringsSep "\n${ind}" (splitString "\n" str);

  # turn an attrset of strings or a list of name-value pairs into a
  # sequence of shell function definitions
  defineFunctions = funcs: concatMapStringsSep "\n"
    ({name, value}: ''
      ${name}() {
      ${indentString "  " ''
        ${removeSuffix "\n" value}''}
      }'')
    (if isList funcs
     then funcs
     else mapAttrsToList nameValuePair funcs);

  # turn an attrset of strings into a case statement, with grouping of
  # like branches
  caseStatement = word: default: branches: ''
    case ${word} in
    ${indentString "  " ''
      ${concatMapStringsSep "\n" ({ patterns, commands }: ''
      ${patterns})
      ${indentString "  " ''
        ${removeSuffix "\n" commands}
        ;;''}'')
        (mapAttrsToList
          (_: patterns:
            { patterns = concatMapStringsSep "|" escapeShellArg patterns;
              # Recover from the unsafeDiscardStringContext below
              commands = branches."${head patterns}"; })
          (groupBy'
            (patterns: {pattern, ...}: [ pattern ] ++ patterns)
            []
            # This is OK because the value gets replaced above
            ({commands, ...}: unsafeDiscardStringContext commands)
            (mapAttrsToList
              (pattern: commands: { inherit pattern commands; })
              branches))
        ++ [ { patterns = "*"; commands = default; } ])}''}
    esac'';

  # Code for the feed() function
  feed_function = defineFunctions {
    feed = ''
      [ "$(jobs | wc -l)" -ge ${toString cfg.jobs} ] && wait -nf
      _feed "$@" &
    '';
  };

  # Code for the feeds() function
  feeds_function = defineFunctions {
    feeds = if length (attrValues cfg.rc.feeds) == 0 then ":" else
      (concatMapStringsSep "\n"
        (feed_args: "feed " + escapeShellArgs feed_args)
        (mapAttrsToList
          (name: {url, baseurl ? "", encoding ? "", ... }:
            [ name url ] ++
            (if encoding != ""
             then [ baseurl encoding ]
             else
               (if baseurl != ""
                then [ baseurl ]
                else [])))
          cfg.rc.feeds));
  };

  # Code for all helper functions defined through cfg.rc.helper
  helper_functions = defineFunctions
    (mapAttrs (_: v: v.code) cfg.rc.helper
     // optionalAttrs
       (any
         (feed: any (name: hasAttr name feed) overrideableFuncs)
         (attrValues cfg.rc.feeds))
       {cp_function = ''
          test -n "$(declare -f "$1")" || return
          eval "''${_/#"$1"/"$2"}"'';});

  # Code to define all configured implementations for ${name} and override the ${name}() function
  functionOverride = name: optionalString
    (any (hasAttr name) (attrValues cfg.rc.feeds)) ''
    cp_function ${name} __${name}
    ${defineFunctions
      ([(nameValuePair "_${name}" (cfg.rc.default."${name}".code or ''__${name} "$@"''))]
       ++ mapAttrsToList
         (n: v: nameValuePair "${name}_${n}" v.code)
         cfg.rc."${name}"
       ++ [{ inherit name;
            value = caseStatement ''"$1"'' ''_${name} "$@" || return''
              (mapAttrs
                (_: v: if ! hasContext v."${name}" && hasAttr v."${name}" cfg.rc."${name}"
                       then ''${name}_${v."${name}"} "$@" || return''
                       else v."${name}")
                (filterAttrs
                  (_: feed: hasAttr name feed && ! isNull feed."${name}")
                  cfg.rc.feeds));}])}'';

  # Generate the entire sfeedrc file
  sfeedrc = resholve.writeScript "sfeedrc" {
    interpreter = "${pkgs.bash}/bin/bash"; # WORKAROUND: Should really be "none" for no shebang, but the resholve api can't handle that
    inputs = unique (concatMap (x: if x ? inputs then x.inputs else []) (concatMap attrValues (attrValues cfg.rc)));
    execer = unique (concatMap (x: if x ? execer then x.execer else []) (concatMap attrValues (attrValues cfg.rc)));
    fake.function = [ "_feed" ] ++ map (name: "__${name}") overrideableFuncs;
  }
    (concatStringsSep "\n\n"
      (map (removeSuffix "\n")
        (filter (x: x != "") (
          [
            feed_function
            feeds_function
            helper_functions
          ] ++ map functionOverride overrideableFuncs))));

  # Options shared by both functions and feeds
  generalModule = {
    options = {
      inputs = mkOption {
        type = listOf package;
        default = [];
        description = "Dependencies of shell code";
      };
      execer = mkOption {
        type = listOf str;
        default = [];
        description = "Execer directives for resholve";
      };
    };
  };

  # Options under cfg.rc.feeds.<name>
  feedModule = submodule [ generalModule {
    options = {
      url = mkOption {
        type = str;
        description = "URL of the feed";
      };
    } // listToAttrs (map (func: nameValuePair func (mkOption {
      type = nullOr str;
      default = null;
      description = "Name of ${func} implementation or shell code";
    })) overrideableFuncs);
  }];

  # Options under cfg.rc.<!feeds>.<name>
  functionModule = submodule [ generalModule {
    options = {
      code = mkOption {
        type = str;
        description = "Function body shell code";
      };
    };
  }];

  # Options under cfg.rc
  rcModule = submoduleWith { modules = [{
    options = {
      feeds = mkOption {
        type = attrsOf feedModule;
        default = {};
        description = "Attribute set of feed descriptions";
      };
      helper = mkOption {
        type = attrsOf functionModule;
        default = {};
        description = "Attribute set of helper functions";
      };
      default = listToAttrs (map (func: nameValuePair func (mkOption {
        type = functionModule;
        default.code = ''__${func} "$@" || return'';
        description = "Default ${func} implementation";
      })) overrideableFuncs);
    } // listToAttrs (map (func: nameValuePair func (mkOption {
      type = attrsOf functionModule;
      default = {};
      description = "Attribute set of ${func} implementations";
    })) overrideableFuncs);
  }];};
in
{
  options = putopt {
    enable = mkEnableOption "sfeed";
    update = mkOption {
      type = str;
      default = "hourly";
      description = "systemd calendar event string describing when to update feeds (see man systemd.time)";
    };
    jobs = mkOption {
      type = ints.positive;
      default = 12;
      description = "number of simultaneous fetches to run";
    };
    rc = mkOption {
      type = rcModule;
      description = "Structured data from which to create sfeedrc";
    };
  };

  config = mkIf cfg.enable {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        sfeed
      ;
    };

    home.file.".sfeed/sfeedrc".source = sfeedrc;

    systemd.user.services.sfeed_update = {
      Unit.Description = "news feed update";
      Service.Environment = [ "PATH=${makeBinPath (attrValues {
        inherit (pkgs)
          sfeed
          curl
          glibc # for iconv
          coreutils
        ;
      })}" ];
      Service.ExecStart = "${pkgs.sfeed}/bin/sfeed_update";
    };
    systemd.user.timers.sfeed_update = {
      Unit.Description = "news feed update timer";
      Install.WantedBy = [ "timers.target" ];
      Timer.OnCalendar = cfg.update;
      Timer.Persistent = true;
    };
  };
}
