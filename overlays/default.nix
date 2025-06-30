inputs@{ self, ... }:
self.lib.importAllExceptWithScope ./. [ "default" ] { inherit inputs; }
