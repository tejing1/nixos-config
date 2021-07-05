{ self, ... }:
self.lib.importAll ../genericModules //
self.lib.importAllExcept ./. [ "default.nix" ]
