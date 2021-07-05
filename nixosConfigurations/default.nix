inputs@{ self, ... }:
self.lib.importAllNamedExceptWithArg ./. [ "default.nix" ] inputs
