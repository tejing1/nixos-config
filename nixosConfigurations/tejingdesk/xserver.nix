{ config, pkgs, ... }:

{
  services.xserver.enable = true;

  # Disable Caps Lock
  services.xserver.xkbOptions = "caps:none";

  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable experimental nvidia_drm framebuffer console
  hardware.nvidia.modesetting.enable = true;
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  boot.initrd.availableKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" "nvidia_uvm" ];

  # 32-bit graphics libraries
  hardware.opengl.driSupport32Bit = true;

  environment.sessionVariables = {
    # I don't know why VA-API can't find the driver without this...
    LIBVA_DRIVER_NAME = "nvidia";

    # Seems to be necessary for the vaapi implementation to function due to an nvidia bug
    NVD_BACKEND = "direct";
  };
}
