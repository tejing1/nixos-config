{ ... }:

{
  boot.kernelModules = [ "kvm-intel" ];

  powerManagement.cpuFreqGovernor = "performance";
}
