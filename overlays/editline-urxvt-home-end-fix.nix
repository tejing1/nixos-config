_inputs:

_final: prev:
{
  # make `nix repl` handle home and end keys in urxvt properly
  editline = prev.editline.overrideAttrs (oldAttrs:
    {
      patches = oldAttrs.patches ++ [ ./editline-urxvt-home-end-fix.patch ];
    }
  );
}
