pkgs: prevPkgs:

# Prevents gh from leaving garbage characters in the input
# buffer when urxvt is set to a transparent background

{
  gh = prevPkgs.gh.overrideAttrs (attrs: prevAttrs: {
    postConfigure = (prevAttrs.postConfigure or "") + ''
      pushd vendor/github.com/muesli/termenv
      chmod -R u+w .
      patch <${./gh-urxvt-fix-termenv.patch}
      chmod -R u-w .
      popd
    '';
  });
}
