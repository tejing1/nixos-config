{
  flake.overlays.editline-urxvt-home-end-fix = final: prev:
    {
      # make `nix repl` handle home and end keys in urxvt properly
      editline = prev.editline.overrideAttrs (oldAttrs:
        {
          patches = oldAttrs.patches or [] ++ [ ./editline-urxvt-home-end-fix.patch ];
        }
      );
    };
}
