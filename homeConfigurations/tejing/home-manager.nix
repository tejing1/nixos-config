{ ... }:

{
  # Automatically (re)start/stop and changed services when activating a home-manager configuration.
  systemd.user.startServices = true;

  home.stateVersion = "20.09";
}
