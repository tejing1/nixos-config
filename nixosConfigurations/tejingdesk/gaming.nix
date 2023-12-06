{ my, pkgs, ...}:

{
  programs.steam.enable = true;

  programs.steam.package = ((my.overlays.steam-fix-screensaver pkgs pkgs).steam.override {
    buildFHSEnv = args: pkgs.buildFHSEnv (args // {
      extraBwrapArgs = (args.extraBwrapArgs or []) ++ [
        "--tmpfs /tmp" # bar steam from /tmp because of steam-for-linux#9121
        "\"\${x11_args[@]}\"" # the steam packaging already does this, but then we rebound /tmp afterward, so we have to redo it.
        "--bind-try /tmp/dumps /tmp/dumps"
      ];
    });
    extraPkgs = p: [
      p.glibc.bin # stops steam complaining about missing /sbin/ldconfig on startup
    ];
    extraEnv = {
      GIO_EXTRA_MODULES = ""; # prevents errors trying to link dconf stuff
    };
  }).overrideAttrs (old: {
    buildCommand = let
      sedscript = builtins.toFile "steam.sed" ''
      # loop start label
      :s

      # Remove breakpad messages
      s/Installing breakpad exception handler for appid([^)]\+)\/version([^)]\+)\/tid([^)]\+)\r\?$//

      # branch to :n, escaping the loop, if previous command did not change pattern space
      Tn

      # pull the next line into the pattern space
      N

      # branch unconditionally to :s
      bs


      # label to escape the loop
      :n

      # remove any newlines (possibly preceded by carriage returns) in the pattern space
      s/\r\?\n//Mg

      # delete pattern space if it is blank or contains solely a carriage return
      /^\r\?$/ d

      # print pattern space
      p
      '';
    in (old.buildCommand or "") + ''
      mv $out/bin/steam $out/bin/steam-unfiltered
      cat <<EOF >$out/bin/steam
      #!/bin/bash
      ${pkgs.faketty}/bin/faketty $out/bin/steam-unfiltered "\$@" |& ${pkgs.gnused}/bin/sed -nuf ${sedscript}
      EOF
      chmod a+x $out/bin/steam
      patchShebangs --host $out/bin/steam
    '';
  });

  # steam and other FHS-installed packages need portals to be able to
  # start other programs without trapping them in their own container.
  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";
}
