{
  boot.kernelParams = [ "quiet" ];
  boot.initrd.verbose = false;

  # Quiet ACPI errors I always see
  boot.consoleLogLevel = 3;

  boot.plymouth.enable = true;
  boot.plymouth.theme = "spinner";
}
