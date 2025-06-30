inputs@{ self, ... }:
self.lib.importAllNamedExceptWithArg ./. [ "default" ] inputs
