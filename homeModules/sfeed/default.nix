{ config, lib, pkgs, ... }:

let
  inherit (builtins) concatStringsSep filter any hasAttr attrValues
    length concatMap isList mapAttrs hasContext
    unsafeDiscardStringContext head listToAttrs;
  inherit (lib) concatMapStringsSep escapeShellArgs escapeShellArg
    optionalString optionalAttrs splitString mapAttrsToList groupBy'
    nameValuePair removeSuffix unique filterAttrs makeBinPath
    mkEnableOption mkOption mkIf;
  inherit (lib.types) attrsOf submodule str ints float listOf package nullOr submoduleWith;
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
      ${indentString "  " (removeSuffix "\n" value)}
      }'')
    (if isList funcs
     then funcs
     else mapAttrsToList nameValuePair funcs);

  # turn an attrset of strings into a case statement, with grouping of
  # like branches
  caseStatement = word: default: branches: ''
    case ${word} in
    ${indentString "  " (concatMapStringsSep "\n" ({ patterns, commands }: ''
      ${patterns})
      ${indentString "  " (removeSuffix "\n" commands + "\n;;")}'')
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
        ++ [ { patterns = "*"; commands = default; } ]))}
    esac'';

  settings = concatMapStringsSep "\n" ({name,value}: "${name}=${escapeShellArg value}") (mapAttrsToList nameValuePair {
    maxjobs = cfg.jobs;
    sfeedpath="${config.home.homeDirectory}/.sfeed/feeds";
    stamppath="${config.home.homeDirectory}/.sfeed/stamps";
  });

  makedirs = concatMapStringsSep "\n" (dir: "mkdir -p ${dir}") [
    ''"$stamppath"''
  ];

  cp_function = defineFunctions {
    cp_function = ''
      test -n "$(declare -f "$1")" || return
      eval "''${_/#"$1"/"$2"}"
    '';
  };

  # Code for the _feed() function
  feed_function = ''
    cp_function _feed __feed
    ${defineFunctions {
    "_feed" = ''
      local name="$(printf '%s' "$1" | tr '/' '_')"
      local file="$sfeedpath/$name"
      local stamp="$stamppath/$name"
      if __feed "$@"; then
        touch "$file"
        rm -f "$stamp"
        return 0
      else
        touch "$stamp"
        return 1
      fi
    '';
    }}'';

  # Code for the adaptfeed() function
  adaptfeed_function = defineFunctions {
    adaptfeed = ''
      local file="''${sfeedpath}/$(printf '%s' "''${10}" | tr '/' '_')"
      local stamp="''${sfeedpath%%/feeds}/stamps/$(printf '%s' "''${10}" | tr '/' '_')"
      mkdir -p "''${sfeedpath%%/feeds}/stamps"

      if [ -e "$file" ]; then
        local lastchecked="$(stat -c'%Y' "$file")"
      else
        local lastchecked=0
      fi

      if [ -e "$stamp" ]; then
        local lastfailed="$(stat -c'%Y' "$stamp")"
      else
        local lastfailed=0
      fi

      # Temporarily set pipefail
      local restore_opts="$(shopt -po pipefail)";set -o pipefail

      if sort -k1,1n "$file" | awk -F'\t' -v recentdiv="$1" -v recentmin="$2" -v regressiondiv="$3" -v regressionmin="$4" -v maxdelay="$5" -v firststeplength="$6" -v weightdoublingtime="$7" -v backofffactor="$8" -v deferprobablility="$9" -v lastchecked="$lastchecked" -v lastfailed="$lastfailed" -f ${./regressions.awk}; then
        # Restore pipefail setting
        eval "$restore_opts"
      else
        # Restore pipefail setting
        eval "$restore_opts"

        shift 9
        feed "$@" || return
      fi
    '';
  };

  # Command to go in the feeds() function, for a given feed
  feed_command = name: {url, baseurl, encoding, adapt, ... }:
    (if adapt.enable then
      "adaptfeed " + escapeShellArgs [
        adapt.recentdiv
        adapt.recentmin
        adapt.regressiondiv
        adapt.regressionmin
        adapt.maxdelay
        adapt.firststeplength
        adapt.weightdoublingtime
        adapt.backofffactor
        adapt.deferprobablility
      ]
     else
       "feed"
    ) + " " + escapeShellArgs (
      [ name url ] ++
      (if encoding != ""
       then [ baseurl encoding ]
       else
         (if baseurl != ""
          then [ baseurl ]
          else []
         )
      )
    );

  # Code for the feeds() function
  feeds_function = defineFunctions {
    feeds = if length (attrValues cfg.rc.feeds) == 0 then ":" else
      concatStringsSep "\n" (mapAttrsToList feed_command cfg.rc.feeds);
  };

  # Code for all helper functions defined through cfg.rc.helper
  helper_functions = defineFunctions (mapAttrs (_: v: v.code) cfg.rc.helper);

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
    interpreter = "none";
    inputs = unique ([ pkgs.gawk ] ++ concatMap (x: if x ? inputs then x.inputs else []) (concatMap attrValues (attrValues cfg.rc)));
    execer = unique (concatMap (x: if x ? execer then x.execer else []) (concatMap attrValues (attrValues cfg.rc)));
    fake.function = [ "feed" "__feed" ] ++ map (name: "__${name}") overrideableFuncs;
  }
    (concatStringsSep "\n\n"
      (map (removeSuffix "\n")
        (filter (x: x != "") (
          [
            settings
            makedirs
            cp_function
            feed_function
            adaptfeed_function
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
      baseurl = mkOption {
        type = str;
        default = "";
        description = "Base URL of the feed. If set to the empty string, the feed url is used.";
      };
      encoding = mkOption {
        type = str;
        default = "";
        description = "Encoding of the feed. If set to the empty string, it is autodetected, falling back to utf-8.";
      };
      adapt = {
        enable = mkEnableOption "adapting the timing of checks for this feed to its history" // {default = true;};
        recentdiv = mkOption {
          type = ints.positive;
          default = 15;
          description = "Divide the time from latest entry to latest check by this to determine recentdelay";
        };
        recentmin = mkOption {
          type = ints.unsigned;
          default = 60*60*24;
          description = "Clamp recentdelay to be at least this";
        };
        regressiondiv = mkOption {
          type = ints.positive;
          default = 50;
          description = "Divide the regression-estimated time per release by this to determine regressiondelay";
        };
        regressionmin = mkOption {
          type = ints.unsigned;
          default = 60*30;
          description = "Clamp regressiondelay to be at least this";
        };
        maxdelay = mkOption {
          type = ints.unsigned;
          default = 60*60*24*30;
          description = "Clamp the minimum of recentdelay and regressiondelay to be at most this, giving the final check delay";
        };
        firststeplength = mkOption {
          type = ints.unsigned;
          default = 60*60;
          description = "The regression should consider the history to start this amount of time before the first entry";
        };
        weightdoublingtime = mkOption {
          type = ints.positive;
          default = 60*60*24*90;
          description = "The doubling time of the exponential time-weighting used in the regression";
        };
        backofffactor = mkOption {
          type = float;
          default = 1.2;
          description = "Check again after a failure if time since last success is more than this multiple of the time between last success and last failure.";
        };
        deferprobablility = mkOption {
          type = float;
          default = 0.1;
          description = "Probability (between 0 and 1) with which to randomly defer checks when they are otherwise considered ready. Breaks up cadence between feeds over time.";
        };
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
    update.averagedelay = mkOption {
      type = ints.positive;
      default = 600;
      description = "Average delay, in seconds, between runs of the service.";
    };
    update.deviation = mkOption {
      type = ints.unsigned;
      default = 30;
      description = "How long, in seconds, to randomly deviate either way on the delay.";
    };
    update.accuracy = mkOption {
      type = ints.unsigned;
      default = 5;
      description = "How long, in seconds, to non-randomly deviate either way on the delay to coalesce with other wakeups.";
    };
    jobs = mkOption {
      type = ints.positive;
      default = 16;
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
      Unit.Description = "news feed updater";
      Service.Environment = [ "PATH=${makeBinPath (attrValues {
        inherit (pkgs)
          sfeed
          curl
          glibc # for iconv
          findutils # for xargs
          coreutils
        ;
      })}" ];
      Service.ExecStart = "${pkgs.sfeed}/bin/sfeed_update";
    };
    systemd.user.timers.sfeed_update = {
      Unit.Description = "news feed update timer";
      Install.WantedBy = [ "timers.target" ];
      Timer.OnActiveSec = 0;
      Timer.OnUnitInactiveSec = cfg.update.averagedelay - cfg.update.deviation - cfg.update.accuracy;
      Timer.RandomizedDelaySec = 2 * cfg.update.deviation;
      Timer.AccuracySec = 2 * cfg.update.accuracy;
    };
  };
}
