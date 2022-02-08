inputs@{ self, ... }:
self.lib.importAllExceptWithScope ./. [ "default.nix" ] { inherit inputs; }
