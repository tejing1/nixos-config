{ self, ... }:
self.lib.importAllExcept ./. [ "default.nix" ]
