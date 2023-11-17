{
  boot.kernelModules = [ "kvm-intel" ];

  powerManagement.cpuFreqGovernor = "performance";

  nixpkgs.hostPlatform = "x86_64-linux";
}
