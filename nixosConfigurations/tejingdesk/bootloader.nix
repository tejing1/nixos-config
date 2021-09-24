{
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.timeout = 1;
  boot.kernelParams = [ "quiet" ];
  boot.loader.grub.gfxmodeEfi = "3840x2160,1280x1024,auto";
}
