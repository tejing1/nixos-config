{ ... }:

{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/98d52540-e5ea-41ee-b012-300cb3424aae";
      fsType = "btrfs";
      options = [ "subvol=tejingdesk/root/new" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/98d52540-e5ea-41ee-b012-300cb3424aae";
      fsType = "btrfs";
      options = [ "subvol=tejingdesk/home/new" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/98d52540-e5ea-41ee-b012-300cb3424aae";
      fsType = "btrfs";
      options = [ "subvol=tejingdesk/boot" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/98d52540-e5ea-41ee-b012-300cb3424aae";
      fsType = "btrfs";
      options = [ "subvol=tejingdesk/nix" ];
    };

  fileSystems."/mnt/cache" =
    { device = "/dev/disk/by-uuid/98d52540-e5ea-41ee-b012-300cb3424aae";
      fsType = "btrfs";
      neededForBoot = true;
    };

  fileSystems."/mnt/persist" =
    { device = "/dev/disk/by-uuid/2bba2a0d-02f8-4243-a139-4c02b5681754";
      fsType = "btrfs";
      neededForBoot = true;
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/3279-FFF8";
      fsType = "vfat";
    };

  swapDevices = [ ];
}
