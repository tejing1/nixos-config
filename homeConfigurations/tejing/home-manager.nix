{ config, pkgs, ... }:

{
  # Automatically (re)start/stop and changed services when activating a home-manager configuration.
  systemd.user.startServices = true;

  systemd.user.services.clean_hm_profile = {
    Unit.Description = "home-manager profile cleaner";
    Service.ExecStart = "${pkgs.nix}/bin/nix profile wipe-history --profile /nix/var/nix/profiles/per-user/${config.home.username}/home-manager";
  };
  systemd.user.timers.clean_hm_profile = {
    Unit.Description = "home-manager profile cleaner timer";
    Install.WantedBy = [ "timers.target" ];
    Timer.OnCalendar = "daily";
    Timer.Persistent = true;
  };

  home.stateVersion = "20.09";
}
