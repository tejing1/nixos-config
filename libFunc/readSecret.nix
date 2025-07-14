let
  inherit (builtins) warn readFile;
in

{
  perPkgs = { my, ... }: {
    my.lib.readSecret =
      if my.lib.isRepoLocked then
        default: file: warn "Building from locked repo. Secrets will be replaced with placeholders." default
      else
        default: file: readFile file
    ;
  };
}
