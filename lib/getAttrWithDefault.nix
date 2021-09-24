let
  inherit (builtins) hasAttr getAttr;
in
_args:

default: attr: set:
# gets attribute 'attr' of set 'set', defaulting to 'default' if absent
if hasAttr attr set then getAttr attr set else default
