pkgs: prevPkgs:

{
  # make `nix repl` handle home and end keys in urxvt properly
  editline = prevPkgs.editline.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [ ./editline-urxvt-home-end-fix.patch ];
  });
}
