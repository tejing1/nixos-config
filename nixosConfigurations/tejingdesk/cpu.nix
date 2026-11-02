{
  hosts.tejingdesk.nixos.cfg = {
    boot.kernelModules = [ "kvm-intel" ];

    powerManagement.cpuFreqGovernor = "performance";
  };
}
