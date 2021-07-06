inputs@{ self, ... }:
self.lib.importAllExceptWithArg ./. [ "default.nix" ] inputs
