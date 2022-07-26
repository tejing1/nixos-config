{ my, pkgs, ... }:
let
  importSecret = if my.lib.isRepoLocked then default: file: default else default: file: import file;
in
importSecret
