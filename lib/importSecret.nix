let
  inherit (builtins) warn;
in

{
  perPkgs = { my, ... }: {
    my.lib.importSecret =
      if my.lib.isRepoLocked then
        default: file: warn "Building from locked repo. Secrets will be replaced with placeholders." default
      else
        default: file: import file
    ;
  };
}
