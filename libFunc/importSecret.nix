{ my, pkgs, ... }:
let
  inherit (builtins) trace;

  importSecret = if my.lib.isRepoLocked then default: file: trace "WARNING: Building from locked repo. Secrets will be replaced with placeholders." default else default: file: import file;
in
importSecret
