{ self, ... }:
self.lib.importAllExcept ./. [ "default" ]
