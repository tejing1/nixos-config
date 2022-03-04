{ pkgs, ... }:

{
  services.xserver.enable = true;

  # Disable Caps Lock
  services.xserver.xkbOptions = "caps:none";

  # Use proprietary nvidia graphics driver
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];

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
}
