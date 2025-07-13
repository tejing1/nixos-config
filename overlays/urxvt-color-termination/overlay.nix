pkgs: prevPkgs:

# Fixes urxvt to prevent garbage characters in the input buffer when
# using tmux. This is upstream code, cherry-picked from pre-release.

{
  rxvt-unicode-unwrapped = prevPkgs.rxvt-unicode-unwrapped.overrideAttrs (attrs: prevAttrs: {
    patches = (prevAttrs.patches or []) ++ [ ./urxvt-color-termination.patch ];
  });
}
