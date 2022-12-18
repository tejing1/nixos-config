{ pkgs, ... }:

{
  services.xserver.enable = true;

  # Disable Caps Lock
  services.xserver.xkbOptions = "caps:none";

  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Fix segfault on login: NixOS/nixpkgs#206663
  nixpkgs.overlays = [ (final: prev: {
    xorg = prev.xorg.overrideScope (xfinal: xprev: {
      xorgserver = xprev.xorgserver.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches or [] ++ [ (builtins.toFile "xserver-segfault-fix.patch" ''
          diff --git a/present/present_scmd.c b/present/present_scmd.c
          index da836ea6b..239055bc1 100644
          --- a/present/present_scmd.c
          +++ b/present/present_scmd.c
          @@ -158,6 +158,9 @@ present_scmd_get_crtc(present_screen_priv_ptr screen_priv, WindowPtr window)
               if (!screen_priv->info)
                   return NULL;

          +    if (!screen_priv->info->get_crtc)
          +        return NULL;
          +
               return (*screen_priv->info->get_crtc)(window);
           }

          @@ -196,6 +199,9 @@ present_flush(WindowPtr window)
               if (!screen_priv->info)
                   return;

          +    if (!screen_priv->info->flush)
          +        return;
          +
               (*screen_priv->info->flush) (window);
           }
        '') ];
      });
    });
  }) ];

  # Hardware-accelerated video decoding
  hardware.opengl.extraPackages = builtins.attrValues {
    inherit (pkgs)
      vaapiVdpau
    ;
  };

  # 32-bit graphics libraries
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = builtins.attrValues {
    inherit (pkgs.pkgsi686Linux)
      vaapiVdpau
    ;
  };

  # workaround nixpkgs#169245
  environment.sessionVariables.LIBVA_DRIVER_NAME = "vdpau";
}
