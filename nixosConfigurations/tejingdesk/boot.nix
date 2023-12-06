{
  boot.kernelParams = [ "quiet" ];

  # Quiet ACPI errors I always see
  boot.consoleLogLevel = 3;

  boot.plymouth.enable = true;
}
